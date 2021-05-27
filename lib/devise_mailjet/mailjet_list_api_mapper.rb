require 'mailjet'

module Devise
  module Models
    module Mailjet
      class MailjetListApiMapper
        # find the list using the mailjet API and save it to a memory cache
        def list_name_to_id(list_name)
          @lists ||= {}
          unless @lists.has_key?(list_name)
            l = ::Mailjet::Contactslist.all(name: list_name, limit: 1).first
            l = ::Mailjet::Contactslist.create(name: list_name) unless l && l.name == list_name
            @lists[list_name] = l.id
          end
          @lists[list_name]
        end

        # find the contact using the mailjet API and save it to a memory cache
        def contact_email_to_id(email)
          @contacts ||= {}
          unless @contacts.has_key?(email)
            c = ::Mailjet::Contact.find(email) # email is a valid key for finding contact resources
            c = ::Mailjet::Contact.create(email: email) unless c && c.email == email
            @contacts[email] = c.id
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
              ::Mailjet::Listrecipient.create(list_id: list_id, contact_id: contact_id, is_unsubscribed: 'false')
            elsif lr.is_unsubscribed
              lr.update_attributes(is_unsubscribed: 'false', unsubscribed_at: nil)
            end
          end
        rescue ::Mailjet::ApiError
          # ignore
        end

        # unsubscribe the user from the named mailing list(s).  list_names can be the name of one list, or an array of
        # several.
        def unsubscribe_from_lists(list_names, email)
          walk_recipients(list_names, email) do |lr, _l, _c|
            lr.update_attributes(is_unsubscribed: 'true', unsubscribed_at: nil) if lr && !lr.is_unsubscribed
          end
        rescue ::Mailjet::ApiError
          # ignore
        end

        class ListLookupError < RuntimeError; end

        private

        def walk_recipients(list_names, email)
          contact_id = contact_email_to_id(email)
          Array(list_names).each do |list_name|
            list_id = list_name_to_id(list_name)
            # Beware: [GET] parameters are not the same than [POST/PUT] parameters
            lr = ::Mailjet::Listrecipient.all(contacts_list: list_id, contact: contact_id, limit: 1).first
            # Make sure the API returned the record we were looking for
            lr = nil unless lr.list_id == list_id && lr.contact_id == contact_id
            yield lr, list_id, contact_id if block_given?
          end
        end
      end
    end
  end
end
