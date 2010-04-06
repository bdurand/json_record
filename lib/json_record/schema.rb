module JsonRecord
  # Definition of a document schema. Defining a schema will define accessor methods for each field and potentially some
  # validators.
  class Schema
    attr_reader :fields, :json_field_name
    
    # Create a schema on the class for a particular field.
    def initialize (klass, json_field_name)
      @json_field_name = json_field_name
      @klass = klass
      @fields = {}
    end
    
    # Define a single valued field in the schema.
    # The first argument is the field name. This must be unique for the class accross all attributes.
    #
    # The optional second argument can be used to specify the class of the field values. It will default to
    # String if not specified. Valid types are String, Integer, Float, Date, Time, DateTime, Boolean, Array, Hash,
    # or any class that inherits from EmbeddedDocument.
    #
    # The last argument can be a hash with any of these keys:
    # * :default -
    # * :required -
    # * :length -
    # * :format -
    # * :in -
    def key (name, *args)
      options = args.extract_options!
      name = name.to_s
      json_type = args.first || String
      
      raise ArgumentError.new("too many arguments (must be 1 or 2 plus an options hash)") if args.length > 1
        
      field = FieldDefinition.new(name, :type => json_type, :default => options[:default])
      fields[name] = field
      add_json_validations(field, options)
      define_json_accessor(field, json_field_name)
    end
    
    # Define a multi valued field in the schema.
    # The first argument is the field name. This must be unique for the class accross all attributes.
    #
    # The optional second argument should be the class of field values. This class must include EmbeddedDocument.
    # If it is not specified, the class name will be guessed from the field name.
    #
    # The last argument can be :unique => field_name which is used to indicate that the values in the field
    # must have unique values in the indicated field name.
    #
    # The value of the field will always be an EmbeddedDocumentArray and adding and removing values is as
    # simple as appending them to the array. You can also call the build method on the array to keep the syntax the
    # same as when dealing with ActiveRecord has_many associations.
    def many (name, *args)
      name = name.to_s
      options = args.extract_options!
      type = args.first || name.singularize.classify.constantize
      field = FieldDefinition.new(name, :type => type, :multivalued => true)
      fields[name] = field
      add_json_validations(field, options)
      define_many_json_accessor(field, json_field_name)
    end
    
    private
    
    def add_json_validations (field, options) #:nodoc:
      @klass.validates_presence_of(field.name) if options[:required]
      @klass.validates_format_of(field.name, :with => options[:format], :allow_blank => true) if options[:format]
      
      if options[:length]
        case options[:length]
        when Fixnum
          @klass.validates_length_of(field.name, :maximum => options[:length], :allow_blank => true)
        when Range
          @klass.validates_length_of(field.name, :in => options[:length], :allow_blank => true)
        when Hash
          @klass.validates_length_of(field.name, options[:length].merge(:allow_blank => true))
        end
      end
      
      if options[:in]
        @klass.validates_inclusion_of(field.name, :in => options[:in], :allow_blank => true)
      end
      
      if field.type == Integer
        @klass.validates_numericality_of(field.name, :only_integer => true, :allow_blank => true)
      elsif field.type == Float
        @klass.validates_numericality_of(field.name, :allow_blank => true)
      elsif [Date, Time, DateTime].include?(field.type)
        @klass.validates_each(field.name) do |record, name, value|
          unless value.is_a?(field.type) or value.blank?
            record.errors.add(name, :invalid, :value => value)
          end
        end
      end
      
      if field.multivalued?
        @klass.validates_each(field.name) do |record, name, value|
          record.errors.add(name, :invalid) unless value.all?{|v| v.valid?}
        end
      elsif field.type < EmbeddedDocument
        @klass.validates_each(field.name) do |record, name, value|
          if value.is_a?(field.type)
            record.errors.add(name, :invalid) unless value.valid?
          end
        end
      end
      
      if field.multivalued? and !options[:unique].blank?
        @klass.validates_each(field.name) do |record, name, value|
          used = {}
          error_found = false
          value.each do |v|
            fval = v.attributes[options[:unique].to_s]
            if used[fval]
              v.errors.add(options[:unique].to_s, :taken, :value => fval)
              error_found = true
            else
              used[fval] = true
            end
          end
          record.errors.add(name, :invalid) if error_found
        end
      end
    end
    
    def define_json_accessor (field, json_field_name) #:nodoc:
      @klass.send(:define_method, field.name) {read_json_attribute(json_field_name, field)}
      @klass.send(:define_method, "#{field.name}?") {!!read_json_attribute(json_field_name, field)} if field.type == Boolean
      @klass.send(:define_method, "#{field.name}=") {|val| write_json_attribute(json_field_name, field, val)}
      @klass.send(:define_method, "#{field.name}_before_type_cast") {self.read_attribute_before_type_cast(field.name)}
      unless field.type.include?(EmbeddedDocument)
        @klass.send(:define_method, "#{field.name}_changed?") {self.send(:attribute_changed?, field.name)}
        @klass.send(:define_method, "#{field.name}_change") {self.send(:attribute_change, field.name)}
        @klass.send(:define_method, "#{field.name}_was") {self.send(:attribute_was, field.name)}
        @klass.send(:define_method, "#{field.name}_will_change!") {self.send(:attribute_will_change!, field.name)}
        @klass.send(:define_method, "reset_#{field.name}!") {self.send(:reset_attribute!, field.name)}
      end
    end
    
    def define_many_json_accessor (field, json_field_name) #:nodoc:
      @klass.send(:define_method, field.name) {self.read_json_attribute(json_field_name, field)}
      @klass.send(:define_method, "#{field.name}=") {|val| self.write_json_attribute(json_field_name, field, val)}
    end
  end
end
