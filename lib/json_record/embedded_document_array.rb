module JsonRecord
  class EmbeddedDocumentArray < Array
    def initialize (klass, parent, objects = [])
      @klass = klass
      @parent = parent
      objects = objects.collect do |obj|
        obj = @klass.new(obj) if obj.is_a?(Hash)
        if obj.is_a?(@klass)
          obj.parent = parent
          obj
        else
          raise ArgumentError.new("#{obj.inspect} is not a #{@klass}") unless obj.is_a?(@klass)
        end
      end
      super(objects)
    end
    
    def << (obj)
      obj = @klass.new(obj) if obj.is_a?(Hash)
      raise ArgumentError.new("#{obj.inspect} is not a #{@klass}") unless obj.is_a?(@klass)
      obj.parent = @parent
      super(obj)
    end
    
    def concat (objects)
      objects = objects.collect do |obj|
        obj = @klass.new(obj) if obj.is_a?(Hash)
        raise ArgumentError.new("#{obj.inspect} is not a #{@klass}") unless obj.is_a?(@klass)
        obj.parent = @parent
        obj
      end
      super(objects)
    end
    
    def build (obj)
      obj = @klass.new(obj) if obj.is_a?(Hash)
      raise ArgumentError.new("#{obj.inspect} is not a #{@klass}") unless obj.is_a?(@klass)
      obj.parent = @parent
      self << obj
      obj
    end
  end
end
