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
  
  module ActiveSupport3Callbacks #:nodoc:
    def before_validation (*args, &block)
      set_callback(:validation, :before, *args, &block)
    end
    
    def after_validation (*args, &block)
      set_callback(:validation, :after, *args, &block)
    end
  end
  
  # Classes that include EmbeddedDocument can be used as the type for keys or many field definitions
  # in Schema. Embedded documents are then extensions of the schema. In this way, complex
  # documents represented in JSON can be deserialized as complex objects.
  #
  # To define the schema for an embedded document, call schema.key or schema.many from the class definition.
  module EmbeddedDocument
    def self.included (base)
      base.send :include, ActiveRecordStub
      base.send :include, ActiveRecord::Validations
      base.send :include, AttributeMethods
      base.send :include, ActiveSupport::Callbacks
      
      if base.respond_to?(:set_callback)
        # Poor man's check for ActiveSupport 3.0 which completely changed around how callbacks work.
        # This is a temporary work around so that the same gem can be compatible with both 2.x and 3.x for now.
        # Incoporating ActiveModel will fix all.
        base.define_callbacks :validation
        base.alias_method_chain(:valid?, :callbacks_3)
        base.extend(ActiveSupport3Callbacks)
      else
        base.define_callbacks :before_validation, :after_validation
        base.alias_method_chain(:valid?, :callbacks)
      end
      
      base.write_inheritable_attribute(:schema, Schema.new(base, nil))
      base.class_inheritable_reader :schema
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
      run_callbacks(:before_validation)
      valid = valid_without_callbacks?
      run_callbacks(:after_validation)
      valid
    end
    
    def valid_with_callbacks_3? #:nodoc:
      run_callbacks(:validation) do
        valid_without_callbacks_3?
      end
    end
    
    protected
    
    def json_attributes
      @json_attributes
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
