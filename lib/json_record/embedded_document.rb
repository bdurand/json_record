module JsonRecord
  # OK, this is ugly, but necessary to get ActiveRecord::Errors to be compatible with
  # EmbeddedDocument. This will all be fixed with Rails 3 and ActiveModel. Until then
  # we'll just live with this.
  module ActiveRecordStub #:nodoc:
    def self.included (base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def human_name (options = {})
        name.split('::').last.humanize
      end
      
      def human_attribute_name (attribute, options = {})
        attribute.to_s.humanize
      end
      
      def self_and_descendants_from_active_record
        [self]
      end
      
      def self_and_descendents_from_active_record
        [self]
      end
    end
    
    def deprecated_callback_method (*args)
    end
    
    private
    def save (*args); end;
    def save! (*args); end;
    def destroy (*args); end;
    def create (*args); end;
    def update (*args); end;
    def new_record?; false; end;
  end
  
  # Subclasses of EmbeddedDocument can be used as the type for keys or many field definitions
  # in Schema. Embedded documents are then extensions of the schema. In this way, complex
  # documents represented in JSON can be deserialized as complex objects.
  class EmbeddedDocument
    include ActiveRecordStub
    include ActiveRecord::Validations
    include AttributeMethods
    
    write_inheritable_attribute(:schema, Schema.new(self, nil))
    class_inheritable_reader :schema
    
    class << self
      # Define a field for the schema. This is a shortcut for calling schema.key.
      # See Schema#key for details. 
      def key (name, *args)
        schema.key(name, *args)
      end
      
      # Define a multivalued field for the schema. This is a shortcut for calling schema.many.
      # See Schema#many for details. 
      def many (name, *args)
        schema.many(name, *args)
      end
    end
    
    # The parent object of the document.
    attr_accessor :parent
    
    # Create an embedded document with the specified attributes.
    def initialize (attrs = {})
      @attributes = {}
      @json_attributes = {}
      attrs.each_pair do |name, value|
        field = schema.fields[name.to_s] || FieldDefinition.new(name, :type => value.class)
        write_attribute(field, value, false, self)
      end
    end
    
    # Get the attributes of the document.
    def attributes
      @json_attributes.reject{|k,v| !schema.fields.include?(k)}
    end
    
    # Get the attribute values of the document before they were type cast.
    def attributes_before_type_cast
      @attributes
    end
    
    # Determine if the document has been changed.
    def changed?
      !changed_attributes.empty?
    end

    # Get the list of attributes changed.
    def changed
      changed_attributes.keys
    end

    # Get a list of changes to the document.
    def changes
      changed.inject({}) {|h, attr| h[attr] = attribute_change(attr); h}
    end
    
    def to_json (*args)
      @json_attributes.to_json(*args)
    end
    
    def eql? (val)
      val.class == self.class && val.attributes == attributes && val.parent == parent
    end
    
    def == (val)
      eql?(val)
    end
    
    def hash
      attributes.hash + parent.hash
    end
    
    def inspect
      "#<#{self.class.name} #{attributes.inspect}>"
    end
    
    protected
    
    def json_attributes
      @json_attributes
    end
    
    def read_json_attribute (json_field_name, field)
      read_attribute(field, self)
    end
    
    def write_json_attribute (json_field_name, field, value, track_changes)
      write_attribute(field, value, track_changes, self)
    end
  
    def changed_attributes
      @changed_attributes ||= {}
    end
    
    def read_attribute_before_type_cast (name)
      @attributes[name.to_s]
    end
    
    def attribute_changed? (name)
      changed_attributes.include?(name.to_s)
    end
    
    def attribute_change (name)
      name = name.to_s
      [changed_attributes[name], read_json_attribute(nil, schema.fields[name])] if attribute_changed?(name)
    end
    
    def attribute_was (name)
      changed_attributes[name.to_s]
    end
  end
end
