require 'mailjet'

module Devise
  module Models
    module Mailjet
      class MailjetListApiMapper
        LISTS_CACHE_KEY = "devise_mailjet/lists"
        CONTACTS_CACHE_KEY = "devise_mailjet/contacts"

        # looks the name up in the cache.  if it doesn't find it, looks it up using the api and saves it to the cache
        def list_name_to_id(list_name)
          load_cached_lists
          unless @lists.has_key?(list_name)
            list = mailjet_list.first(name: list_name)
            list = mailjet_list.create(name: list_name) if list.nil?
            @lists[list_name] = list.id
            save_cached_lists
          end
          @lists[list_name]
        end

        def contact_email_to_id(email)
          load_cached_contacts
          unless @contacts.has_key?(email)
            contact = mailjet_contact.find(email) # email is a valid key for finding contact resources
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
        def subscribe_to_lists(list_names, email)
          walk_recipients(list_names, email) do |lr, list_id, contact_id|
            if lr.nil?
              mailjet_rcpt.create(list_ID: list_id, contact_ID: contact_id, is_active: true)
            elsif lr.is_unsubscribed
              lr.is_unsubscribed = false
              lr.is_active = true
              lr.save
            end
          end
        rescue Mailjet::ApiError
          # ignore
        end

        # unsubscribe the user from the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        def unsubscribe_from_lists(list_names, email)
          walk_recipients(list_names, email) do |lr, _, _|
            if lr && !lr.is_unsubscribed
              lr.is_unsubscribed = true
              lr.is_active = false
              lr.save
            end
          end
        rescue Mailjet::ApiError
          # ignore
        end

        class ListLookupError < RuntimeError; end

        private

        def walk_recipients(list_names, email)
          contact_id = contact_email_to_id(email)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list_id = list_name_to_id(list_name)
            lr = mailjet_rcpt.first('ContactsList' => list_id, 'Contact' =>  contact_id)
            yield lr, list_id, contact_id if block_given?
          end
        end

        # load the list from the cache
        def load_cached_lists
          @lists ||= Rails.cache.fetch(LISTS_CACHE_KEY) do
            {}
          end.dup
        end

        # save the modified list back to the cache
        def save_cached_lists
          Rails.cache.write(LISTS_CACHE_KEY, @lists)
        end

        # load contacts from the cache
        def load_cached_contacts
          @contacts ||= Rails.cache.fetch(CONTACTS_CACHE_KEY) do
            {}
          end.dup
        end

        # save the modified contacts back to the cache
        def save_cached_contacts
          Rails.cache.write(CONTACTS_CACHE_KEY, @contacts)
        end

        # the mailjet api helpers
        def mailjet_contact
          ::Mailjet::Contact
        end

        def mailjet_list
          ::Mailjet::Contactslist
        end

        def mailjet_rcpt
          ::Mailjet::Listrecipient
        end
      end
    end
  end
end
