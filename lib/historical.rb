require 'historical/railtie'

module Historical
  autoload :ModelHistory,             'historical/model_history'
  autoload :ActiveRecord,             'historical/active_record'
  autoload :ClassBuilder,             'historical/class_builder'
  autoload :MongoMapperEnhancements,  'historical/mongo_mapper_enhancements'
  
  module Models
    autoload :Pool,                   'historical/models/pool'
    autoload :AttributeDiff,          'historical/models/attribute_diff'
    autoload :ModelVersion,           'historical/models/model_version'
  end
  
  IGNORED_ATTRIBUTES = [:id]
  
  @@historical_models = []
  
  def self.historical_models
    @@historical_models
  end
  
  def self.boot!
    Historical::Models::Pool.clear!
    
    historical_models.each do |model|
      model.generate_historical_models!
    end
  end
end
