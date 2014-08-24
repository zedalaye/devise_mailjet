require 'devise'

require "devise_mailjet/version"

module DeviseMailjet
  class Engine < Rails::Engine
  end
  # Your code goes here...
end

module Devise
  # Public: Default mailing list for user to join.  This can be an array of strings, or just one string.
  # By default, this is "Site List".  If this will be configurable for each user, override
  # mailjet_lists_to_join returning the list name or an array of list names for the user to
  # join.
  # Set mailing_list_name in the Devise configuration file (config/initializers/devise.rb)
  #
  #   Devise.mailing_list_name = "Your Mailing List Name"
  mattr_accessor :mailing_list_name
  @@mailing_list_name = "Newsletter"

  # Public: Determines if the checkbox for the user to opt-in to the mailing list should
  # be checked by default, or not.  Defaults to true.
  # Set mailing_list_opt_in_by_default in the Devise configuration file (config/initializers/devise.rb)
  #
  #   Devise.mailing_list_opt_in_by_default = false
  mattr_accessor :mailing_list_opt_in_by_default
  @@mailing_list_opt_in_by_default = true
end

Devise.add_module :mailjet, :model => 'devise_mailjet/model'

require 'devise_mailjet/mailjet_list_api_mapper'
