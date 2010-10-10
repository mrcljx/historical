module Historical::Models
  # The diff of an attribute (specialized by a type qualifier)
  class AttributeDiff
    
    # MongoMappers supported native Ruby types
    SUPPORTED_NATIVE_RUBY_TYPES = %w{Date String Time Boolean Integer Float Binary}
    
    include MongoMapper::EmbeddedDocument
    plugin Historical::MongoMapper::Enhancements
    
    # @return [String] The attribute name
    key :attribute,       String, :required => true
    
    # @return [String] The attribute type (string, integer, float)
    key :attribute_type,  String, :required => true
    
    # @return The old value
    # @private
    key :_old_value,      Object
    
    # @return The new value
    # @private
    key :_new_value,      Object
  
    # @return [ModelVersion::Diff] The parent diff model.
    attr_accessor :parent
  
    alias_method :old_value, :_old_value
    alias_method :new_value, :_new_value    

    protected :_old_value=, :_new_value=, :_old_value, :_new_value
    
    # @return [Class] The specialized {AttributeDiff} class for a attribute type
    # @private
    def self.specialized_for(parent, attribute)
      type = detect_attribute_type(parent, attribute)
      Historical::Models.const_get(specialized_class_name(type))
    end
  
    def old_value=(value)
      self._old_value = value
    end
  
    def new_value=(value)
      self._new_value = value
    end
  
    # Get attribute type for an attribute
    def self.detect_attribute_type(parent, attribute)
      model_class = parent.record.class
      
      column = model_class.columns.select do |c|
        c.name.to_s == attribute.to_s
      end.first
    
      column ? column.type.to_s : nil
    end
    
    # Generates subclasses of {AttributeDiff} for each type in {SUPPORTED_NATIVE_RUBY_TYPES}
    # @private
    def self.generate_subclasses!
      SUPPORTED_NATIVE_RUBY_TYPES.each do |type|
        diff_class = Class.new(self)
        type_class = type.constantize

        diff_class.send :key, :_old_value, type_class
        diff_class.send :key, :_new_value, type_class

        const_name = specialized_class_name(type_class)
        namespace = Historical::Models
        
        namespace.send(:remove_const, const_name) if namespace.const_defined?(const_name)
        namespace.const_set(const_name, diff_class)
        
        diff_class.unloadable
      end
    end
    
    protected
    
    # A unique subclass name for the type diffs.
    # @private
    def self.specialized_class_name(type)
      ruby_type = case type
        when Class
          type.name
        else
          Historical::ActiveRecord.sql_to_type(type)
      end
      "#{ruby_type}#{simple_name}"
    end
    
    # @return [String] Pure classname without modules
    # @private
    def self.simple_name
      name.to_s.demodulize
    end
  end
end
