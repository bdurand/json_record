require 'zlib'

module JsonRecord
  class JsonField
    include AttributeMethods
    
    def initialize (record, name, schemas)
      @record = record
      @name = name.to_s
      @schemas = schemas
      @attributes = nil
      json_column = record.class.columns_hash[@name]
      raise ArgumentError.new("column #{name} does not exist in #{table_name}") unless json_column
      @compressed = json_column.type == :binary
    end
    
    def serialize
      if @attributes
        stripped_attributes = {}
        @attributes.each_pair{|k, v| stripped_attributes[k] = v unless v.blank?}
        json = stripped_attributes.to_json
        json = Zlib::Deflate.deflate(json) if json and @compressed
        @record[@name] = json
      end
    end
    
    def deserialize
      @attributes = {}
      @schemas.each do |schema|
        schema.fields.values.each do |field|
          @attributes[field.name] = field.multivalued? ? EmbeddedDocumentArray.new(field.type, @record) : field.default
        end
      end
      
      unless @record[@name].blank?
        json = @record[@name]
        json = Zlib::Inflate.inflate(json) if @compressed
        do_not_track_changes = Thread.current[:do_not_track_json_field_changes]
        Thread.current[:do_not_track_json_field_changes] = true
        begin
          ActiveSupport::JSON.decode(json).each_pair do |attr_name, attr_value|
            setter = "#{attr_name}=".to_sym
            if @record.respond_to?(setter)
              @record.send(setter, attr_value)
            else
              field = nil
              @schemas.each{|schema| field = schema.fields[attr_name]; break if field}
              field = FieldDefinition.new(attr_name, :type => attr_value.class) unless field
              write_attribute(field, attr_value, @record)
            end
          end
        ensure
          Thread.current[:do_not_track_json_field_changes] = do_not_track_changes
        end
      end
    end
    
    def json_attributes
      deserialize unless @attributes
      @attributes
    end
    
    def changes
      @record.changes
    end
    
    def changed_attributes
      @record.instance_variable_get(:@changed_attributes)
    end
    
  end
end
