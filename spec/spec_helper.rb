require 'rubygems'

active_record_version = ENV["ACTIVE_RECORD_VERSION"] || [">= 3.0.0"]
active_record_version = [active_record_version] unless active_record_version.is_a?(Array)
puts "gem 'activerecord', #{active_record_version.inspect}"
gem 'activerecord', *active_record_version

require 'spec'
require 'active_record'
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}"

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
