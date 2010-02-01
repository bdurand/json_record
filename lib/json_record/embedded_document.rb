module JsonRecord
  module ActiveRecordStub
    private
    def save (*args); end;
    def save! (*args); end;
    def destroy (*args); end;
    def create (*args); end;
    def update (*args); end;
  end
  
  class EmbeddedDocument
    include ActiveRecordStub
    #include ActiveRecord::Validations
    include AttributeMethods
    
    class_inheritable_reader :schema
    
    class << self
      def key (name, *args)
        write_inheritable_attribute(:schema, Schema.new(self, nil)) unless schema
        schema.key(name, *args)
      end
      
      def many (name, *args)
        write_inheritable_attribute(:schema, Schema.new(self, nil)) unless schema
        schema.many(name, *args)
      end
    end
    
    attr_accessor :parent
    
    def initialize (attributes = {})
      @attributes = {}
      @json_attributes = {}
      attributes.each_pair do |name, value|
        write_attribute(schema.fields[name.to_s], value, false, self)
      end
    end
    
    def attributes
      @json_attributes
    end
    
    def attributes_before_type_cast
      @attributes
    end
    
    def changed?
      !changed_attributes.empty?
    end

    def changed
      changed_attributes.keys
    end

    def changes
      changed.inject({}) { |h, attr| h[attr] = attribute_change(attr); h }
    end
    
    def to_json (*args)
      @json_attributes.to_json(*args)
    end
    
    def eql? (val)
      val.class == self.class && val.attributes == attributes && value.parent == parent
    end
    
    protected
    
    def read_json_attribute (json_field_name, field)
      read_attribute(field)
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
      [changed_attributes[name], read_json_attribute(name)] if attribute_changed?(name)
    end
    
    def attribute_was (name)
      changed_attributes[name.to_s]
    end
  end
end
