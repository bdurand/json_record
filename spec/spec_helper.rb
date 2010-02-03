require 'rubygems'
require 'spec'
require 'active_record'
ActiveRecord.load_all!
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'json_record'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))
