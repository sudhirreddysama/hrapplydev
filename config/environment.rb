# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# RAILS_ENV='production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'activemerchant', :lib => "active_merchant", :version => '1.3.2'

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  config.log_level = :info

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  # config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_hr_session' + (RAILS_ENV == 'development' ? 'dev' : ''),
    :secret      => '208e1e73bd0bd677b796d7f122c984147eaf694bbb69af1bc00b887d4af513e16b3e8fbdedfb95b72c4765ff7ec8b14b02916b9c75c525bca347750eabbfba15'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  #config.action_controller.relative_url_root = '/hrapply'
  
  
end

require 'digest'
require 'digest/sha1'
require 'hash_ext'
require 'will_paginate'
require 'db'
require 'active_merchant'
require 'net/http'
require 'fastercsv'

ActionController::AbstractRequest.relative_url_root = '/hrapply' + (RAILS_ENV == 'development' ? 'dev' : '')



Time::DATE_FORMATS[:dt] = '%m/%d/%y %I:%M%p'

ExceptionNotifier.exception_recipients = %w(jessesternberg@monroecounty.gov)# rgrape@monroecounty.gov sduritza@monroecounty.gov)
ExceptionNotifier.sender_address = %("HRApply Error" <hrapply@monroecounty.gov>)

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings[:address] = '10.100.224.102' #'173.84.13.11' #'66.192.47.11'
ActionMailer::Base.raise_delivery_errors = false
#ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.sendmail_settings[:arguments] = '-i -t -fwebmaster@monroecounty.gov'


#ActionMailer::Base.smtp_settings[:user_name] = 'websitesmtp'
#ActionMailer::Base.smtp_settings[:password] = 'smtprelay0507'


if RAILS_ENV == 'production'
	PAYPAL_LOGIN = 'ksemmler_api1.monroecounty.gov'
	PAYPAL_PASSWORD = 'KQF8ZEZVL9LJC3FN'
	ActiveMerchant::Billing::PaypalGateway.signature = 'AKMKTKK8oBT1JFUrYTtaF5NSRJXjAK2RHLHvLjmNcJrbaUtQ1xBEzciP'
	ActiveMerchant::Billing::Base.mode = :production
else
	PAYPAL_LOGIN = 'jesse_1223309245_biz_api1.catalogandcommerce.com'
	PAYPAL_PASSWORD = '1223309253'
	ActiveMerchant::Billing::PaypalGateway.signature = 'AFcWxV21C7fd0v3bYYYRCpSSRl31A5WzswmJwUUrYjY-SiwhIGzmIRbX'
	ActiveMerchant::Billing::Base.mode = :test
end





# Fix calendar date select to accept 2-digit years.
class Date 
	class << self 
		def _parse_with_auto_year_adjust(str, comp=false) 
			elem = _parse_without_auto_year_adjust(str, comp=false) 
			if elem[:year] && (0..100).include?(elem[:year]) 
				elem[:year] += 1900 
				elem[:year] += 100 if elem[:year] < 1969 
			end
			elem 
		end

		alias_method_chain :_parse, :auto_year_adjust
	end
end 
