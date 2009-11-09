require 'models/version'
require 'models/attribute_change'

module Historical
  IGNORED_ATTRIBUTES = %w{created_at updated_at}
  VALID_HISTORICAL_OPTIONS = [:timestamps, :except, :only, :merge]
  VALID_HISTORICAL_MERGE_OPTIONS = [:if_time_difference_is_less_than]

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Decides wether the +model+ with the specified changes can be merged. This
    # is based on whether there exists a version which the new changes could
    # be merged with and whether the time threshold allows merging.
    def can_merge?(model, changes)
      last = model.versions.most_recent.first
      return false unless last
      
      if self.historical_merge_options[:if_time_difference_is_less_than]
        last.created_at >= self.historical_merge_options[:if_time_difference_is_less_than].ago
      else
        raise "unknown merge settings"
      end
    end
    
    def validate_historical_options(options) # :nodoc:
      options.assert_valid_keys(VALID_HISTORICAL_OPTIONS)
    end
    
    def validate_historical_merge_options(options) # :nodoc:
      return unless options
      options.assert_valid_keys(VALID_HISTORICAL_MERGE_OPTIONS)
    end
  
    # == Configuration options
    #
    # * <tt>except</tt> - excludes the specified colums from versioning
    # * <tt>only</tt> - only includes the specified columns for versioning
    # * <tt>timestamps</tt> - whether or not to include created_at and updated_at for versioning
    # * <tt>merge</tt> - options for version-merging to avoid clutter (default: false)
    def historical(options = {})
      validate_historical_options(options)
      validate_historical_merge_options(options[:merge])
      
      send :include, InstanceMethods
      
      cattr_accessor :historical_merge_options
      self.historical_merge_options = options.delete(:merge) || false
      
      has_many :versions, :as => :target, :dependent => :destroy
      has_many :attribute_changes, :through => :versions
      
      after_update do |model|
        next unless model.changed? and model.changes
        
        changes = model.changes.reject { |k,v| IGNORED_ATTRIBUTES.include? k }
        next if changes.empty?
        
        Version.transaction do
          if self.historical_merge_options and can_merge?(model, changes)
            model.versions.most_recent.first.merge!(changes)
          else
            version = model.versions.create!
            changes.collect do |attribute, diff|
              version.attribute_changes.create! do |change|
                change.version = version
                change.attribute = attribute.to_s
                change.update_by_diff(diff)
              end
            end
          end
        end
      end
    end
  end

  module InstanceMethods
    
  end
end

ActiveRecord::Base.send :include, Historical
