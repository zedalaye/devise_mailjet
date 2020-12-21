module Devise
  module Models
    module Mailjet
      class MailjetWorker
        include Sidekiq::Worker

        def perform(action, list_names, email, config)
          if config.is_a?(Hash)
            ::Mailjet.configure do |c|
              c.api_version  = 'v3'
              c.api_key      = config['api_key']
              c.secret_key   = config['secret_key']
              c.default_from = config['default_from']
            end
          end

          mapper = MailjetListApiMapper.new
          if action == 'subscribe'
            mapper.subscribe_to_lists(list_names, email)
          elsif action == 'unsubscribe'
            mapper.unsubscribe_from_lists(list_names, email)
          end
        end
      end
    end
  end
end
