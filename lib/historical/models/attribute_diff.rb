module Historical::Models
  class AttributeDiff
    include MongoMapper::EmbeddedDocument
  
    key :_type,           String
    
    key :attribute,       String, :required => true
    key :attribute_type,  String, :required => true
    
    key :_old_value,      Object
    key :_new_value,      Object
  
    attr_accessor :parent
  
    alias_method :old_value, :_old_value
    alias_method :new_value, :_new_value    

    protected :_old_value=, :_new_value=, :_old_value, :_new_value
    
    def self.specialized_for(parent, attribute)
      type = detect_attribute_type(parent, attribute)
      Historical::Models.const_get(specialized_class_name(type))
    end
    
    def self.specialized_class_name(type)
      ruby_type = Historical::ActiveRecord.sql_to_type(type)
      "#{ruby_type}#{simple_name}"
    end
    
    def self.simple_name
      name.to_s.demodulize
    end
  
    def old_value=(value)
      self._old_value = cast_value(value)
    end
  
    def new_value=(value)
      self._new_value = cast_value(value)
    end
  
    def self.detect_attribute_type(parent, attribute)
      model_class = parent.record.class
      
      column = model_class.columns.select do |c|
        c.name.to_s == attribute.to_s
      end.first
    
      column ? column.type.to_s : nil
    end
    
    protected
    
    def cast_value(value)
      value
    end
  end
  
  %w{Date String Time Boolean Integer Float Binary}.each do |type|
    superclass = AttributeDiff
    diff_class = Class.new(superclass)
    type_class = type.constantize
    
    diff_class.send :key, :_old_value, type_class
    diff_class.send :key, :_new_value, type_class
    
    self.const_set "#{type}#{superclass.simple_name}", diff_class
  end
end
