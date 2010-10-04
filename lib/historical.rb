require 'historical/railtie' if defined?(Rails::Railtie)

module Historical
  IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]
  
  autoload :ModelHistory, "historical/model_history"
  autoload :ActiveRecord, "historical/active_record"
  autoload :ClassBuilder, "historical/class_builder"
  autoload :MongoMapperEnhancements, "historical/mongo_mapper_enhancements"
  
  @@historical_models = []
  
  def self.historical_models
    @@historical_models
  end
  
  def self.boot!
    historical_models.each do |model|
      model.generate_historical_models!
    end
  end
  
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
    autoload :ModelVersion,   'historical/models/model_version'
  end
end
