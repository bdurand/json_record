require 'active_record'

begin
  require 'json'
rescue LoadError
  ActiveRecord::Base.logger.warn("*** You really should install the json gem for optimal performance with json_record ***")
end

unless defined?(Boolean)
  class Boolean
  end
end

require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'attribute_methods'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'embedded_document'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'embedded_document_array'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'field_definition'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'json_field'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'schema'))
require File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'serialized'))
