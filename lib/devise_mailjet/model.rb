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
    #   mailjet_api_key: The API key for accessing the mailjet service.  To generate a new API key, go to the
    #                      account tab in your MailJet account and select API Keys & Authorized Apps, then add
    #                      a key.  This defaults to 'your_api_key'
    #
    #   double_opt_in: Requires that users must click a link in a confirmation email to be added to your mailing list.
    #                  Defaults to false.
    #
    #   send_welcome_email: Whether or not the user will get a final Welcome email    
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

      # Set this to true to have the user automatically join the mailjet_lists_to_join
      def join_mailing_list=(join)
        join.downcase! if join.is_a?(String)
        true_values = ['yes','true',true,'1',1]
        join = true_values.include?(join)
        @join_mailing_list = join
      end

      #
      def join_mailing_list
        @join_mailing_list.nil? ? self.class.mailing_list_opt_in_by_default : @join_mailing_list
      end

      # The mailing list or lists the user will join
      # Should return either a single string or an array of strings.  By default, returns the mailing_list_name
      # configuration option.  If you want to customize the lists based on other information, override this method in
      # your model.
      def mailjet_lists_to_join
        self.class.mailing_list_name
      end

      # Add the user to the mailjet list with the specified name
      def add_to_mailjet_list(list_name)
        mapper = mailjet_list_mapper.respond_to?(:delay) ? mailjet_list_mapper.delay : mailjet_list_mapper
        options = self.respond_to?(:mailjet_list_subscribe_options) ? mailjet_list_subscribe_options : {}
        mapper.subscribe_to_lists(list_name, self.email, options)        
      end

      # remove the user from the mailjet list with the specified name
      def remove_from_mailjet_list(list_name)
        mapper = mailjet_list_mapper.respond_to?(:delay) ? mailjet_list_mapper.delay : mailjet_list_mapper
        mapper.unsubscribe_from_lists(list_name, self.email)
      end

      # Commit the user to the mailing list if they have selected to join
      def commit_mailing_list_join
        add_to_mailjet_list(mailjet_lists_to_join) if @join_mailing_list
      end

      # mapper that helps convert list names to mailjet ids
      def mailjet_list_mapper
        @@mailjet_list_mapper ||= MailjetListApiMapper.new(self.class.mailjet_api_key, self.class.double_opt_in, self.class.send_welcome_email)
      end

      module ClassMethods
        Devise::Models.config(self, :mailjet_api_key)
        Devise::Models.config(self, :mailing_list_name)
        Devise::Models.config(self, :mailing_list_opt_in_by_default)
        Devise::Models.config(self, :double_opt_in)
        Devise::Models.config(self, :send_welcome_email)
      end
    end
  end
end
