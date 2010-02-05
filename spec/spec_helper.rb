require 'rubygems'

if ENV["ACTIVE_RECORD_VERSION"]
  gem 'activerecord', ENV["ACTIVE_RECORD_VERSION"]
end

require 'spec'
require 'active_record'
ActiveRecord.load_all!
puts "Testing Against ActiveRecord #{ActiveRecord::VERSION::STRING}"

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
