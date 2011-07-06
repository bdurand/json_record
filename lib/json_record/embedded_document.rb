module JsonRecord
  # Classes that include EmbeddedDocument can be used as the type for keys or many field definitions
  # in Schema. Embedded documents are then extensions of the schema. In this way, complex
  # documents represented in JSON can be deserialized as complex objects.
  #
  # To define the schema for an embedded document, call schema.key or schema.many from the class definition.
  module EmbeddedDocument
    def self.included (base)
      base.send :include, ActiveModel::AttributeMethods
      base.send :include, ActiveModel::Dirty
      base.send :include, ActiveModel::Validations
      base.send :include, AttributeMethods
      base.send :include, ActiveSupport::Callbacks
      
      base.define_callbacks :validation
      base.alias_method_chain(:valid?, :callbacks)
      base.extend ValidationCallbacks
      
      base.class_attribute :schema
      base.schema = Schema.new(base, nil)
    end
    
    module ValidationCallbacks #:nodoc:
      def before_validation (*args, &block)
        set_callback(:validation, :before, *args, &block)
      end

      def after_validation (*args, &block)
        set_callback(:validation, :after, *args, &block)
      end
    end
    
    # The parent object of the document.
    attr_accessor :parent
    
    # Create an embedded document with the specified attributes.
    def initialize (attrs = {})
      @attributes = {}
      @json_attributes = {}
      self.attributes = attrs
    end
    
    # Get the attributes of the document.
    def attributes
      @json_attributes.reject{|k,v| !schema.fields.include?(k)}
    end
    
    # Set all the attributes at once.
    def attributes= (attrs)
      attrs.each_pair do |name, value|
        field = schema.fields[name.to_s] || FieldDefinition.new(name, :type => value.class)
        setter = "#{name}=".to_sym
        if respond_to?(setter)
          send(setter, value)
        else
          write_attribute(field, value, self)
        end
      end
    end
    
    # Get the attribute values of the document before they were type cast.
    def attributes_before_type_cast
      json_attributes_before_type_cast
    end
    
    # Get a field from the schema with the specified name.
    def [] (name)
      field = schema.fields[name.to_s]
      read_attribute(field, self) if field
    end
    
    # Set a field from the schema with the specified name.
    def []= (name, value)
      field = schema.fields[name.to_s] || FieldDefinition.new(name, :type => value.class)
      write_attribute(field, value, self)
    end
    
    def to_json (*args)
      @json_attributes.to_json(*args)
    end
    
    def to_hash
      @json_attributes
    end
    
    def eql? (val)
      val.class == self.class && val.attributes == attributes && val.parent == parent
    end
    
    def == (val)
      eql?(val)
    end
    
    def equal? (val)
      eql?(val)
    end
    
    def hash
      attributes.hash + parent.hash
    end
    
    def inspect
      "#<#{self.class.name} #{attributes.inspect}>"
    end
    
    def valid_with_callbacks? #:nodoc:
      run_callbacks(:validation) do
        valid_without_callbacks?
      end
    end
    
    protected
    
    def json_attributes
      @json_attributes
    end
    
    def json_attributes_before_type_cast
      @attributes
    end
    
    def read_json_attribute (json_field_name, field)
      read_attribute(field, self)
    end
    
    def write_json_attribute (json_field_name, field, value)
      write_attribute(field, value, self)
    end
      
    def changed_attributes
      @changed_attributes ||= {}
    end
    
    def read_attribute_before_type_cast (name)
      @attributes[name.to_s]
    end
  end
end
