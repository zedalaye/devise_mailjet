# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "devise_mailjet/version"

Gem::Specification.new do |s|
  s.name        = "devise_mailjet"
  s.version     = DeviseMailjet::VERSION
  s.authors     = ["Justin Cunningham", "Pierre Yager"]
  s.email       = ["justin@compucatedsolutions.com", "pierre@levosgien.net"]
  s.homepage    = "https://github.com/zedalaye/devise_mailjet"
  s.summary     = %q{Easy MailJet integration for Devise}
  s.description = %q{Devise MailJet adds a MailJet option to devise that easily enables users to join your mailing list when they create an account.}
  s.licenses    = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  {
    'rails'  => '< 7',
    'devise' => '< 5',
    'devise-bootstrap-views' => '< 1',
    'mailjet' => '< 2'
  }.each do |lib, version|
    s.add_runtime_dependency(lib, *version)
  end

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
