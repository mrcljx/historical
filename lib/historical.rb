require 'historical/railtie'
require 'active_support'

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
  mattr_reader :historical_models
  
  def self.boot!
    Historical::Models::Pool.clear!
    
    historical_models.each do |model|
      model.generate_historical_models!
    end
  end
end
