module Historical::MongoMapper
  # Contains some helper methods for better MongoMapper integration.
  module Enhancements
    extend ActiveSupport::Concern
    
    module ClassMethods
      def ensure_embedded_indexes
        associations.each do |assoc|
          next unless assoc.one?
          
          klass = assoc.klass
          next unless klass.embeddable?
          
          klass.embedded_indexes.each do |index|
            new_index = case index
            when Array
              index.collect do |s|
                k, v = *s
                [:"#{assoc.name}.#{k}", v]
              end
            else
              :"#{assoc.name}.#{index}"
            end
            
            ensure_index(new_index)
          end
        end
      end
      
      def embedded_indexes
        @@embedded_indexes ||= []
      end
      
      def ensure_index(*args)
        if embeddable?
          embedded_indexes << args
        else
          super
        end
      end
      
      # Simple `belongs_to` relation to an ActiveRecord model.
      # 
      # @param name The name of the relation.
      # @option options [String] :class_name (name.classify) The class name of the model (if it can't be guessed from the name)
      # @option options [true,false] :polymorphic (false) Will create an additional {name}_type key in the model.
      def belongs_to_active_record(name, options = {})
        ar_id_field   = "#{name}_id"
        ar_type_field = "#{name}_type"
      
        polymorphic   = options.delete(:polymorphic)
        class_name    = options.delete(:class_name)
        index         = options.delete(:index)
        model_class   = nil
      
        # classname
        unless polymorphic
          if class_name
            model_class = class_name.is_a?(Class) ? class_name.name : class_name.classify
          else
            model_class = name.to_s.classify
          end
        end
      
        # define the keys
        key ar_id_field,    Integer,  options
        key ar_type_field,  String,   options if polymorphic
        
        if index
          index_spec =  []
          index_spec << [ar_id_field,   1]
          index_spec << [ar_type_field, 1] if polymorphic
          
          ensure_index(index_spec)
        end
      
        # getter
        define_method name do
          if id = send(ar_id_field)
            if polymorphic
              type_class = send(ar_type_field)
              type_class ? type_class.constantize.find(id) : nil
            else
              model_class.constantize.find(id)
            end
          else
            nil
          end
        end
      
        # setter
        define_method "#{name}=" do |val|
          id = type = nil
        
          if val
            raise "expected an instace of ActiveRecord::Base, got: #{val.class.name}" unless val.is_a?(::ActiveRecord::Base)
            type  = val.class.name
            id    = val.id
          end
        
          send("#{ar_id_field}=",   id)
          send("#{ar_type_field}=", type) if polymorphic
        end
      end
    end
  end
end