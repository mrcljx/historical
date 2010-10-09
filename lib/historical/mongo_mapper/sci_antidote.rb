module Historical::MongoMapper
  module SciAntidote
    module ClassMethods
      def inherited(subclass)
        super
        remove_key("_type")
        subclass.remove_key("_type")
      end
      
      def remove_key(key)
        k = keys.delete(key)
        return unless k
        
        if method_defined?(k.name)
          undef_method(k.name)
          undef_method("#{k.name}_before_typecast")
          undef_method("#{k.name}=")
          undef_method("#{k.name}?")
        end
        
        subclasses.each do |s|
          s.remove_key(key)
        end
      end
    end
  end
end