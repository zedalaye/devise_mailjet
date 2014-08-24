require 'mailjet'

module Devise
  module Models
    module Mailjet
      class MailjetListApiMapper
        LIST_CACHE_KEY = "devise_mailjet/lists"
        CONTACT_CACHE_KEY = "devise_mailjet/contacts"

        # looks the name up in the cache.  if it doesn't find it, looks it up using the api and saves it to the cache
        def list_name_to_id(list_name)
          load_cached_lists
          unless @lists.has_key?(list_name)
            list = mailjet_list.first(name: list_name)
            list = mailjet_list.create(name: liste_name) if list.nil?
            @lists[list_name] = list.id
            save_cached_lists
          end
          @lists[list_name]
        end

        def contact_email_to_id(email)
          load_cached_contacts
          unless @contacts.has_key?(email)
            contact = mailjet_contact.first(email: email)
            contact = mailjet_contact.create(email: email) if contact.nil?
            @contacts[email] = contact.id
            save_cached_contacts
          end
          @contacts[email]
        end

        # subscribes the user to the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        #
        # NOTE: Do not use this method unless the user has opted in.
        def subscribe_to_lists(list_names, email, options)
          contact_id = contact_email_to_id(email)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list_id = list_name_to_id(list_name)
            lr = mailjet_rcpt.first('ListID' => list_id, 'ContactID' => contact_id)
            if lr
              lr.is_unsubscribed = false
              lr.is_active = true
              lr.save
            else
              mailjet_rcpt.create('ListID' => list_id, 'ContactID' => contact_id, is_active: true)
            end
          end
        end

        # unsubscribe the user from the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        def unsubscribe_from_lists(list_names, email)
          contact_id = contact_email_to_id(email)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list_id = list_name_to_id(list_name)
            lr = mailjet_rcpt.first('ListID' => list_id, 'ContactID' => contact_id)
            if lr
              lr.is_unsubscribed = true
              lr.is_active = false
              lr.save
            end
          end
        end


        class ListLookupError < RuntimeError; end

        private

        # load the list from the cache
        def load_cached_lists
          @lists ||= Rails.cache.fetch(LIST_CACHE_KEY) do
            {}
          end.dup
        end

        # save the modified list back to the cache
        def save_cached_lists
          Rails.cache.write(LIST_CACHE_KEY, @lists)
        end

        # load contacts from the cache
        def load_cached_contacts
          @contacts ||= Rails.cache.fetch(CONTACT_CACHE_KEY) do
            {}
          end.dup
        end

        # save the modified contacts back to the cache
        def save_cached_contacts
          Rails.cache.write(CONTACT_CACHE_KEY, @contacts)
        end

        # the mailjet api helpers
        def mailjet_contact
          Mailjet::Contact
        end

        def mailjet_list
          Mailjet::Contactslist
        end

        def mailjet_rcpt
          Mailjet::ListRecipient
        end
      end
    end
  end
end
