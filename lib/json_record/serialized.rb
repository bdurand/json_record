module JsonRecord
  module Serialized
    def self.included (base)
      base.class_inheritable_accessor :json_serialized_fields
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def serialize_to_json (field_name, &block)
        field_name = field_name.to_s
        self.json_serialized_fields ||= {}
        include InstanceMethods unless include?(InstanceMethods)
        schema = Schema.new(self, field_name)
        field_schemas = json_serialized_fields[field_name]
        if field_schemas
          field_schemas = field_schemas.dup
        else
          field_schemas = []
        end
        json_serialized_fields[field_name] = field_schemas
        field_schemas << schema
        block.call(schema) if block
      end
    end
    
    module InstanceMethods
      def self.included (base)
        base.before_save :serialize_json_attributes
        base.after_validation :validate_many_json_attributes
        base.alias_method_chain :reload, :serialized_json
        base.alias_method_chain :attributes, :serialized_json
      end
      
      def json_fields
        unless @json_fields
          @json_fields = {}
          json_serialized_fields.each_pair do |name, schemas|
            @json_fields[name] = JsonField.new(self, name, schemas)
          end
        end
        @json_fields
      end
      
      def reload_with_serialized_json (*args)
        @json_fields = nil
        reload_without_serialized_json(*args)
      end
      
      def attributes_with_serialized_json
        attrs = attributes_without_serialized_json.merge(json_attributes)
        json_serialized_fields.keys.each{|name| attrs.delete(name)}
        return attrs
      end
      
      protected
      
      def json_attributes
        attrs = {}
        json_fields.values.each do |field|
          attrs.merge!(field.attributes)
        end
        attrs
      end
      
      def read_json_attribute (json_field_name, field)
        json_fields[json_field_name].read_attribute(field, self)
      end
      
      def write_json_attribute (json_field_name, field, value, track_changes)
        json_fields[json_field_name].write_attribute(field, value, track_changes, self)
      end
      
      def serialize_json_attributes
        json_fields.values.each{|field| field.serialize} if @json_fields
      end
      
      def deserialize_json_attributes
        json_fields.values.each{|field| field.deserialize} if @json_fields
      end
      
      def validate_many_json_attributes
        json_fields.values.each
      end
    end
  end
end
