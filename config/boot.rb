ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'logger' # Ruby 3.2 no longer autoloads stdlib logger; ActiveSupport (Rails 7.0.x) references Logger during boot.
require 'bundler/setup' # Set up gems listed in the Gemfile.
