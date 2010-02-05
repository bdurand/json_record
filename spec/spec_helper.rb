require 'rubygems'

active_record_version = ENV["ACTIVE_RECORD_VERSION"] || ">= 3.0"
if active_record_version
  gem 'activerecord', active_record_version
end

require 'spec'
require 'active_record'
ActiveRecord.load_all!
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}"

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
