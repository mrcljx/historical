module Historical
  module MongoMapperEnhancements
    def belongs_to_active_record(name, options = {})
      ar_id_field   = "#{name}_id"
      ar_type_field = "#{name}_type"
      
      polymorphic   = options.delete(:polymorphic)
      class_name    = options.delete(:class_name)
      model_class   = nil
      
      unless polymorphic
        if class_name
          model_class = class_name.is_a?(Class) ? class_name : class_name.constantize
        else
          model_class = name.to_s.classify.constantize
        end
      end
      
      key ar_id_field,    Integer,  options
      key ar_type_field,  String,   options if polymorphic
      
      define_method name do
        id    = send(ar_id_field)
        
        type_class = polymorphic ? send(ar_type_field).constantize : model_class
        type.constantize.find(id)
      end
      
      define_method "#{name}=" do |val|
        id = type = nil
        
        if val
          raise "expected an instace of ActiveRecord::Base, got: #{val.class.name}" unless val.is?(ActiveRecord::Base)
          type  = val.class.name
          id    = val.id
        end
        
        send("#{ar_id_field}=",   id)
        send("#{ar_type_field}=", type) if polymorphic
      end
    end
  end
end