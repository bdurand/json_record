require 'rubygems'

active_record_version = ENV["ACTIVE_RECORD_VERSION"] || [">=3.0.0"]
active_record_version = [active_record_version] unless active_record_version.is_a?(Array)
gem 'activerecord', *active_record_version

require 'active_record'
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}"

ActiveRecord::Base.establish_connection("adapter" => "sqlite3", "database" => ":memory:")

require File.expand_path("../../lib/json_record.rb", __FILE__)
require File.expand_path("../test_models.rb", __FILE__)
