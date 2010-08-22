module JsonRecord
  # A definition of a JSON field in a Schema.
  class FieldDefinition
    BOOLEAN_MAPPING = {
      true => true, 'true' => true, 'TRUE' => true, 'True' => true, 't' => true, 'T' => true, '1' => true, 1 => true, 1.0 => true,
      false => false, 'false' => false, 'FALSE' => false, 'False' => false, 'f' => false, 'F' => false, '0' => false, 0 => false, 0.0 => false, nil => false
    }
    
    attr_reader :name, :type
    
    # Define a field. Options should include :type with the class of the field. Other options available are
    # :multivalued and :default.
    def initialize (name, options = {})
      @name = name.to_s
      @type = options[:type] || String
      @multivalued = !!options[:multivalued]
      @default = options[:default]
      if [Hash, Array].include?(@type) and @default.nil?
        @default = @type.new
      end
    end
    
    # Get the default value.
    def default
      (@default.dup rescue @default )if @default
    end
    
    # Indicates the field is multivalued.
    def multivalued?
      @multivalued
    end
    
    # Convert a value to the proper class for storing it in the field. If the value can't be converted,
    # the original value will be returned. Blank values are always translated to nil. Hashes will be converted
    # to EmbeddedDocument objects if the field type extends from EmbeddedDocument.
    def convert (val)
      return nil if val.blank? and val != false
      if @type == String
        return val.to_s
      elsif @type == Integer
        return Kernel.Integer(val) rescue val
      elsif @type == Float
        return Kernel.Float(val) rescue val
      elsif @type == Boolean
        v = BOOLEAN_MAPPING[val]
        v = val.to_s.downcase == 'true' if v.nil? # Check all mixed case spellings for true
        return v
      elsif @type == Date
        if val.is_a?(Date)
          return val
        elsif val.is_a?(Time)
          return val.to_date
        else
          return Date.parse(val.to_s) rescue val
        end
      elsif @type == Time
        if val.is_a?(Time)
          return Time.at((val.to_i / 60) * 60).utc
        else
          return Time.parse(val).utc rescue val
        end
      elsif @type == DateTime
        if val.is_a?(DateTime)
          return val.utc
        else
          return DateTime.parse(val).utc rescue val
        end
      elsif @type == Array
        val = [val] unless val.is_a?(Array)
        raise ArgumentError.new("#{name} must be an Array") unless val.is_a?(Array)
        return val
      elsif @type == Hash
        raise ArgumentError.new("#{name} must be a Hash") unless val.is_a?(Hash)
        return val
      elsif @type == BigDecimal
      	return BigDecimal.new(val.to_s)
      else
        if val.is_a?(@type)
          val
        elsif val.is_a?(Hash) and (@type < EmbeddedDocument)
          return @type.new(val)
        else
          raise ArgumentError.new("#{name} must be a #{@type}")
        end
      end
    end
    
  end
end
