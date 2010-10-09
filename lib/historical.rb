require 'historical/railtie'
require 'active_support'

# Main module for the Historical gem
module Historical
  autoload :ActiveRecord,             'historical/active_record'
  autoload :ClassBuilder,             'historical/class_builder'
  autoload :ModelHistory,             'historical/model_history'
  
  # Additional MongoMapper plugins
  module MongoMapper
    autoload :Enhancements,  'historical/mongo_mapper/enhancements'
    autoload :SciAntidote,  'historical/mongo_mapper/sci_antidote'
  end
  
  # MongoDB models used by Historical are stored here
  module Models
    autoload :AttributeDiff,          'historical/models/attribute_diff'
    autoload :ModelVersion,           'historical/models/model_version'
    autoload :Pool,                   'historical/models/pool'
  end
  
  IGNORED_ATTRIBUTES = [:id]
  
  @@historical_models = []
  @@autospawn_creation = true
  @@booted = false
  
  mattr_accessor :autospawn_creation
  mattr_reader :historical_models
  def self.booted?; @@booted; end
  
  def self.reset!
    @@booted = false
    @@historical_models = []
    Historical::Models::Pool.clear!
  end
  
  # Generates all customized models.
  def self.boot!
    return if booted?
    
    Historical::Models::Pool.clear!
    Historical::Models::AttributeDiff.generate_subclasses!
    
    historical_models.each do |model|
      model.generate_historical_models!
    end
    
    @@booted = true
    @@historical_models = ImmediateLoader.new
  end
  
  class ImmediateLoader
    def <<(model)
      model.generate_historical_models!
    end
    
    def each
      false
    end
  end
end
