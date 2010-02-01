module JsonRecord
  class Schema
    attr_reader :fields, :json_field_name
    
    def initialize (klass, json_field_name)
      @json_field_name = json_field_name
      @klass = klass
      @fields = {}
    end
    
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
    
    def many (name, type = nil)
      name = name.to_s
      type = name.singularize.classify.constantize unless type
      field = FieldDefinition.new(name, :type => type, :multivalued => true)
      fields[name] = field
      define_many_json_accessor(field, json_field_name)
    end
    
    private
    
    def add_json_validations (field, options)
      @klass.validates_presence_of(field.name) if options[:required]
      @klass.validates_format_of(attribute, :with => options[:format]) if options[:format]
      
      if options[:length]
        case options[:length]
        when Fixnum
          @klass.validates_length_of(field.name, :maximum => options[:length], :allow_blank => true)
        when Range
          @klass.validates_length_of(field.name, :in => options[:length], :allow_blank => true)
        when Hash
          @klass.validates_length_of(field.name, options[:length].merge(allow_blank => true))
        end
      end
      
      if options[:in]
        @klass.validates_inclusion_of(field.name, :in => options[:in], :allow_blank => true)
      end
      
      if options[:format]
        @klass.validates_format_of(field.name, :with => options[:format], :allow_blank => true)
      end
      
      if field.type == Integer
        @klass.validates_numericality_of(field.name, :only_integer => true, :allow_blank => true)
      elsif field.type == Float
        @klass.validates_numericality_of(field.name, :allow_blank => true)
      elsif [Date, Time, DateTime].include?(field.type)
        @klass.validates_each(field.name) do |record, name, value|
          unless value.is_a?(field.type) or record.read_attribute_before_type_cast(name).blank?
            record.errors.add(name, :invalid, :value => value)
          end
        end
      end
    end
    
    def define_json_accessor (field, json_field_name)
      @klass.send(:define_method, field.name) {read_json_attribute(json_field_name, field)}
      @klass.send(:define_method, "#{field.name}?") {!!read_json_attribute(json_field_name, field)} if field.type == Boolean
      @klass.send(:define_method, "#{field.name}=") {|val| write_json_attribute(json_field_name, field, val, true)}
      @klass.send(:define_method, "#{field.name}_changed?") {self.send(:attribute_changed?, field.name)}
      @klass.send(:define_method, "#{field.name}_change") {self.send(:attribute_change, field.name)}
      @klass.send(:define_method, "#{field.name}_was") {self.send(:attribute_was, field.name)}
      @klass.send(:define_method, "#{field.name}_before_type_cast") {self.read_attribute_before_type_cast(field.name)}
    end
    
    def define_many_json_accessor (field, json_field_name)
      @klass.send(:define_method, field.name) {self.read_json_attribute(json_field_name, field)}
      @klass.send(:define_method, "#{field.name}=") {|val| self.write_json_attribute(json_field_name, field, val, true)}
    end
    
  end
end
