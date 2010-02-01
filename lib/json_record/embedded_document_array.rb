module JsonRecord
  class EmbeddedDocumentArray < Array
    def initialize (klass, parent, objects = [])
      @klass = klass
      @parent = parent
      objects = objects.collect do |obj|
        if obj.is_a?(Hash)
          @klass.new(obj)
        elsif obj.is_a?(@klass)
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
      obj.parent = parent
      super(obj)
    end
    
    def concat (objects)
      objects.each do |obj|
        raise ArgumentError.new("#{obj.inspect} is not a #{@klass}") unless obj.is_a?(@klass)
        obj.parent = parent
      end
      super
    end
    
    def build (obj)
      obj = @klass.new(obj) if obj.is_a?(Hash)
      obj.parent = parent
      self << obj
      obj
    end
  end
end
