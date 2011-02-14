require 'historical/railtie'
require 'active_support'

# Main module for the Historical gem
module Historical
  extend ActiveSupport::Autoload
  autoload :ActiveRecord
  autoload :ClassBuilder
  autoload :ModelHistory

  # Additional MongoMapper plugins
  module MongoMapper
    extend ActiveSupport::Autoload
    autoload :Enhancements
    autoload :SciAntidote
  end

  # MongoDB models used by Historical are stored here
  module Models
    extend ActiveSupport::Autoload
    autoload :AttributeDiff
    autoload :ModelVersion

    class << self
      def const_missing_with_generator(sym)
        result = nil
        result = case sym.to_s
        when /^(.+)AttributeDiff$/
          AttributeDiff.generate_subclass!($1.constantize)
        # when /^(.+)ModelVersion$/
          # ModelVersion.for_class($1.constantize)
        end
        result || const_missing_without_generator
      end

      alias const_missing_without_generator const_missing
      alias const_missing const_missing_with_generator
    end
  end

  IGNORED_ATTRIBUTES = [:id]

  @@historical_models = []
  @@autospawn_creation = true
  @@booted = false

  mattr_accessor :autospawn_creation

  def self.reset!
    historical_models.each do |m|
      Historical::Models::ModelVersion.descendants.delete(m.historical_version_class)
      Historical::Models::ModelVersion::Diff.descendants.delete(m.historical_diff_class)
      Historical::Models::ModelVersion::Meta.descendants.delete(m.historical_meta_class)
    end

    @@historical_models.clear
    @@booted = false
  end

  # Eager-loads all models
  def self.boot!
    historical_models.each do |klass|
      klass.generate_historical_models!
    end

    @booted = true
  end

  def self.register(klass)
    historical_models << klass
    klass.generate_historical_models! if @booted
  end

  protected

  mattr_reader :historical_models
end
