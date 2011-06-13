require 'active_record'

unless defined?(Yajl) || defined?(JSON)
  if ActiveRecord::Base.logger
    ActiveRecord::Base.logger.warn("*** You really should install the json or yajl gem for optimal performance with json_record ***")
  end
end

unless defined?(Boolean)
  class Boolean
  end
end

module JsonRecord
  autoload :AttributeMethods, File.expand_path("../json_record/attribute_methods.rb", __FILE__)
  autoload :EmbeddedDocument, File.expand_path("../json_record/embedded_document.rb", __FILE__)
  autoload :EmbeddedDocumentArray, File.expand_path("../json_record/embedded_document_array.rb", __FILE__)
  autoload :FieldDefinition, File.expand_path("../json_record/field_definition.rb", __FILE__)
  autoload :JsonField, File.expand_path("../json_record/json_field.rb", __FILE__)
  autoload :Schema, File.expand_path("../json_record/schema.rb", __FILE__)
  autoload :Serialized, File.expand_path("../json_record/serialized.rb", __FILE__)
end

ActiveRecord::Base.send(:include, JsonRecord::Serialized)