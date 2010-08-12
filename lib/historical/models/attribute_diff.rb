module Historical::Models
  class AttributeDiff
    include MongoMapper::EmbeddedDocument
  
    key :attribute,       String, :required => true
    key :attribute_type,  String, :required => true
    key :_old_value,      Object
    key :_new_value,      Object
  
    alias :old_value :_old_value
    alias :new_value :_new_value
  
    validate :check_attribute_type
  
    def old_value=(value)
      self._old_value = value
    end
  
    def new_value=(value)
      self._new_value = value
    end
  
    def self.detect_attribute_type(parent, attribute)
      column = parent.record.class.columns.select do |c|
        c.name.to_s == attribute.to_s
      end.first
    
      column ? column.type.to_s : nil
    end
  
    protected :_old_value=, :_new_value=, :_old_value, :_new_value
  
    def check_attribute_type
      #errors.add(:attribute_type, :not_set)
    end
  end
end
