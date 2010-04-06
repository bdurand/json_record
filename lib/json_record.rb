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

module JsonRecord
  autoload :Schema, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'schema'))
  autoload :AttributeMethods, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'attribute_methods'))
  autoload :EmbeddedDocument, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'embedded_document'))
  autoload :EmbeddedDocumentArray, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'embedded_document_array'))
  autoload :FieldDefinition, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'field_definition'))
  autoload :JsonField, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'json_field'))
  autoload :Serialized, File.expand_path(File.join(File.dirname(__FILE__), 'json_record', 'serialized'))
end

ActiveRecord::Base.send(:include, JsonRecord::Serialized)
