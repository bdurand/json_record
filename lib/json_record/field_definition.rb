module JsonRecord
  class FieldDefinition
    BOOLEAN_MAPPING = {
      true => true, 'true' => true, 'TRUE' => true, 'True' => true, 't' => true, 'T' => true, '1' => true, 1 => true, 1.0 => true,
      false => false, 'false' => false, 'FALSE' => false, 'False' => false, 'f' => false, 'F' => false, '0' => false, 0 => false, 0.0 => false, nil => false
    }
    
    attr_reader :name, :type, :default
    
    def initialize (name, options = {})
      @name = name.to_s
      @type = options[:type] || String
      @multivalued = options[:multivalued]
      @default = options[:default]
    end
    
    def multivalued?
      @multivalued
    end
    
    def convert (val)
      return nil if val.blank?
      begin
        if @type == String
          return val.to_s
        elsif @type == Integer
          return Kernel.Integer(val)
        elsif @type == Float
          return Kernel.Float(val)
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
            return Date.parse(val.to_s)
          end
        elsif @type == Time
          if val.is_a?(Time)
            return Time.at((val.to_i / 60) * 60).utc
          else
            return Time.parse(val).utc
          end
        elsif @type == DateTime
          if val.is_a?(DateTime)
            return val.utc
          else
            return DateTime.parse(val).utc
          end
        elsif @type == Array
          val = [val] unless val.is_a?(Array)
          return val
        else
          if val.is_a?(@type)
            val
          elsif val.is_a?(Hash) and (@type < EmbeddedDocument)
            return @type.new(val)
          else
            return val
          end
        end
      rescue
        return val
      end
    end
    
  end
end
