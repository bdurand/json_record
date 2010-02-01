require 'active_record'

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
