module JsonRecord
  module AttributeMethods
    def read_attribute (field, context)
      if field.multivalued?
        arr = attributes[field.name]
        unless arr
          arr = EmbeddedDocumentArray.new(field.type, context)
          attributes[field.name] = arr
        end
        return arr
      else
        val = attributes[field.name]
        if val.nil? and !field.default.nil?
          val = field.default
          attributes[field.name] = val
        end
        return val
      end
    end

    def write_attribute (field, val, track_changes, context)
      if field.multivalued?
        attributes[field.name] = EmbeddedDocumentArray.new(field.type, context, val)
      else
        old_value = read_attribute(field, context)
        converted_value = field.convert(val)
        converted_value.parent = context if converted_value.is_a?(EmbeddedDocument)
        unless old_value == converted_value
          if track_changes
            changes = changed_attributes
            if changes.include?(field.name)
              changes.delete(field.name) if converted_value == changes[field.name]
            else
              old_value = (old_value.clone rescue old_value) unless old_value.nil?
              changes[field.name] = old_value
            end
          end
          unless converted_value.nil?
            attributes[field.name] = converted_value
          else
            attributes.delete(field.name)
          end
        end
        context.attributes_before_type_cast[field.name] = val
      end
      return val
    end
  end
end
