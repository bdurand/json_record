require 'rubygems'

active_record_version = ENV["ACTIVE_RECORD_VERSION"] || [">= 2.2.2", "< 3.0"]
active_record_version = [active_record_version] unless active_record_version.is_a?(Array)
gem 'activerecord', *active_record_version

require 'spec'
require 'active_record'
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}" if defined?(ActiveRecord::VERSION)
ActiveRecord.load_all! if ActiveRecord.respond_to?(:load_all!)

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
