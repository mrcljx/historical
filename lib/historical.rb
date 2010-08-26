require 'historical/railtie' if defined?(Rails::Railtie)

module Historical
  IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]
  
  autoload :ModelHistory, "historical/model_history"
  autoload :ActiveRecord, "historical/active_record"
  autoload :MongoMapperEnhancements, "historical/mongo_mapper_enhancements"
  
  module Models
    module Pool
      # cached classes are stored here
      
      def self.pooled(name)
        @@class_pool ||= {}
        return @@class_pool[name] if @@class_pool[name]
        
        cls = yield
        
        Historical::Models::Pool::const_set(name, cls)
        @@class_pool[name] = cls
        
        cls
      end
      
      def self.pooled_name(specialized_for, parent)
        "#{specialized_for.name.demodulize}#{parent.name.demodulize}"
      end
    end
    
    autoload :AttributeDiff,  'historical/models/attribute_diff'
    autoload :ModelDiff,      'historical/models/model_diff'
    autoload :ModelVersion,   'historical/models/model_version'
  end
end
