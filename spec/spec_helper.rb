require 'rubygems'

active_record_version = ENV["ACTIVE_RECORD_VERSION"] || [">= 2.1", "< 3.0"]
active_record_version = [active_record_version] unless active_record_version.is_a?(Array)
gem 'activerecord', *active_record_version

require 'spec'
require 'active_record'
ActiveRecord.load_all!
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}"

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
