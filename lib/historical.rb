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
  end

  IGNORED_ATTRIBUTES = [:id]

  @@historical_models = []
  @@pending_models = []
  @@autospawn_creation = true
  @@booted = false

  mattr_accessor :autospawn_creation

  def self.booted?; @@booted; end

  def self.reset!
    @@booted = false

    historical_models.each do |m|
      Historical::Models::ModelVersion.descendants.delete(m.historical_version_class)
      Historical::Models::ModelVersion::Diff.descendants.delete(m.historical_diff_class)
      Historical::Models::ModelVersion::Meta.descendants.delete(m.historical_meta_class)
    end

    historical_models.clear
  end

  # Generates all customized models.
  def self.boot!
    return if booted?
    @@booted = true

    Historical::Models::AttributeDiff.generate_subclasses!

    pending_models.each do |klass|
      register(klass)
    end

    pending_models.clear
  end

  def self.register(klass, now = false)
    if now or booted?
      if klass.table_exists?
        klass.generate_historical_models!
        historical_models << klass
      else
        # puts "Warning: Table for class #{klass} does not exist."
      end
    else
      pending_models << klass
    end
  end

  protected

  mattr_reader :historical_models
  mattr_reader :pending_models
end
