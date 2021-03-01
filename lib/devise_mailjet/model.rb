module Devise
  module Models
    # Mailjet is responsible for joining users to mailjet lists when the create accounts with devise
    # When a user is created, and join_mailing_list is set to true, they will automatically be added to one or more
    # mailing lists returned by mailjet_lists_to_join.
    #
    # Configuration
    #
    #   mailing_list_name: Default mailing list for user to join.  This can be an array of strings, or just one string.
    #                      By default, this is "Site List".  If this will be configurable for each user, override
    #                      mailjet_lists_to_join returning the list name or an array of list names for the user to
    #                      join.
    #
    #   mailing_list_opt_in_by_default: Determines if the checkbox for the user to opt-in to the mailing list should
    #                                   be checked by default, or not.  Defaults to true.
    #
    # Examples:
    #
    #   User.find(1).add_to_mailjet_list('Site Administrators List')
    #   User.find(1).remove_from_mailjet_list('Site Administrators List')
    #
    #   u = User.new
    #   u.join_mailing_list = true
    #   u.save
    module Mailjet
      extend ActiveSupport::Concern

      included do
        after_create :commit_mailing_list_join
        after_update :commit_mailing_list_join
      end

      def self.required_fields(klass)
        [ :join_mailing_list ]
      end

      # Set this to true to have the user automatically join the mailjet_lists_to_join
      def join_mailing_list=(join)
        join.downcase! if join.is_a?(String)
        write_attribute(:join_mailing_list, ['yes', 'true', true, '1', 1].include?(join))
      end

      def join_mailing_list
        (new_record?) ? self.class.mailing_list_opt_in_by_default : read_attribute(:join_mailing_list)
      end

      # The mailing list or lists the user will join
      # Should return nil, a single string or an array of strings.
      # By default, returns the mailing_list_name configuration option. If you want to customize the lists based on
      # other information, override this method in your model.
      # Returning nil disables the (un)subscription to the mailing lists
      def mailjet_lists_to_join
         self.class.mailing_list_name
      end

      # Add the user to the mailjet list with the specified name
      def add_to_mailjet_list(list_name)
        if defined?(Sidekiq::Worker)
          MailjetWorker.perform_async(:subscribe, list_name, self.email, mailjet_config)
        else
          mapper = mailjet_list_mapper.respond_to?(:delay) ? mailjet_list_mapper.delay : mailjet_list_mapper
          # options = self.respond_to?(:mailjet_list_subscribe_options) ? mailjet_list_subscribe_options : {}
          mapper.subscribe_to_lists(list_name, self.email)
        end
      end

      # remove the user from the mailjet list with the specified name
      def remove_from_mailjet_list(list_name)
        if defined?(Sidekiq::Worker)
          MailjetWorker.perform_async(:unsubscribe, list_name, self.email, mailjet_config)
        else
          mapper = mailjet_list_mapper.respond_to?(:delay) ? mailjet_list_mapper.delay : mailjet_list_mapper
          mapper.unsubscribe_from_lists(list_name, self.email)
        end
      end

      # Commit the user to the mailing list if they have selected to join
      def commit_mailing_list_join
        lists = mailjet_lists_to_join
        return if Array(lists).empty?

        if self.join_mailing_list
          add_to_mailjet_list(lists)
        else
          remove_from_mailjet_list(lists)
        end
      end

      # mapper that helps convert list names to mailjet ids
      def mailjet_list_mapper
        @@mailjet_list_api_mapper ||= MailjetListApiMapper.new
      end

      module ClassMethods
        Devise::Models.config(self, :mailing_list_name)
        Devise::Models.config(self, :mailing_list_opt_in_by_default)
      end

      private

      def mailjet_config
        {
          'api_key'      => ::Mailjet.config.api_key,
          'secret_key'   => ::Mailjet.config.secret_key,
          'default_from' => ::Mailjet.config.default_from
        }
      end
    end
  end
end
