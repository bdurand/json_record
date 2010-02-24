module JsonRecord
  # Adds the serialized JSON behavior to ActiveRecord.
  module Serialized
    def self.included (base)
      base.extend(ActsMethods)
    end
    
    module ActsMethods
      # Specify a field name that contains serialized JSON. The block will be yielded to with a
      # Schema object that can then be used to define the fields in the JSON document. A class
      # can have multiple fields that store JSON documents if necessary.
      def serialize_to_json (field_name, &block)
        unless include?(InstanceMethods)
          class_inheritable_accessor :json_serialized_fields
          extend ClassMethods
          include InstanceMethods
        end
        field_name = field_name.to_s
        self.json_serialized_fields ||= {}
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
    
    module ClassMethods
      # Get the json field and the field definition of the JSON field from the schema it is defined in.
      def json_field_definition (name)
        if json_serialized_fields
          name = name.to_s
          json_serialized_fields.each_pair do |fname, schemas|
            schemas.each do |schema|
              field = schema.fields[name];
              return [fname, field] if field
            end
          end
        end
        return nil
      end
    end
    
    module InstanceMethods
      def self.included (base)
        base.before_save :serialize_json_attributes
        base.alias_method_chain :reload, :serialized_json
        base.alias_method_chain :attributes, :serialized_json
        base.alias_method_chain :read_attribute, :serialized_json
        base.alias_method_chain :write_attribute, :serialized_json
      end
      
      # Get the JsonField objects for the record.
      def json_fields
        unless @json_fields
          @json_fields = {}
          json_serialized_fields.each_pair do |name, schemas|
            @json_fields[name] = JsonField.new(self, name, schemas)
          end
        end
        @json_fields
      end
      
      def reload_with_serialized_json (*args) #:nodoc:
        @json_fields = nil
        reload_without_serialized_json(*args)
      end
      
      def attributes_with_serialized_json #:nodoc:
        attrs = json_attributes.reject{|k,v| !json_field_names.include?(k)}
        attrs.merge!(attributes_without_serialized_json)
        json_serialized_fields.keys.each{|name| attrs.delete(name)}
        return attrs
      end
      
      def read_attribute_with_serialized_json (name)
        name = name.to_s
        json_field, field_definition = self.class.json_field_definition(name)
        if field_definition
          read_json_attribute(json_field, field_definition)
        else
          read_attribute_without_serialized_json(name)
        end
      end
      
      def write_attribute_with_serialized_json (name, value)
        name = name.to_s
        json_field, field_definition = self.class.json_field_definition(name)
        if field_definition
          write_json_attribute(json_field, field_definition, value)
        else
          write_attribute_without_serialized_json(name, value)
        end
      end
      
      protected
      
      # Returns a hash of all the JsonField objects merged together.
      def json_attributes
        attrs = {}
        json_fields.values.each do |field|
          attrs.merge!(field.json_attributes)
        end
        attrs
      end
      
      def json_field_names
        @json_field_names = json_serialized_fields.values.flatten.collect{|s| s.fields.keys}.flatten
      end
      
      # Read a field value from a JsonField.
      def read_json_attribute (json_field_name, field)
        json_fields[json_field_name].read_attribute(field, self)
      end
      
      # Write a field value to a JsonField.
      def write_json_attribute (json_field_name, field, value)
        json_fields[json_field_name].write_attribute(field, value, self)
      end
      
      # Serialize the JSON in the record into JsonField objects.
      def serialize_json_attributes
        json_fields.values.each{|field| field.serialize} if @json_fields
      end
      
      # Write out the JSON representation of the JsonField objects to the database fields.
      def deserialize_json_attributes
        json_fields.values.each{|field| field.deserialize} if @json_fields
      end
    end
  end
end
