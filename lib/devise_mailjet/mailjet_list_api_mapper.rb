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
              ::Mailjet::Listrecipient.create('ListID' => list_id, 'ContactID' => contact_id, is_active: true)
            elsif lr.is_unsubscribed
              lr.is_unsubscribed = false
              lr.is_active = true
              lr.save
            end
          end
        rescue ::Mailjet::ApiError
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
        rescue ::Mailjet::ApiError
          # ignore
        end

        class ListLookupError < RuntimeError; end

        private

        def walk_recipients(list_names, email)
          contact_id = contact_email_to_id(email)
          list_names = [list_names] unless list_names.is_a?(Array)
          list_names.each do |list_name|
            list_id = list_name_to_id(list_name)
            lr = ::Mailjet::Listrecipient.all('ContactsList' => list_id, 'Contact' =>  contact_id, limit: 1).first
            yield lr, list_id, contact_id if block_given?
          end
        end
      end
    end
  end
end
