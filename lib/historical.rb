require 'models/version'
require 'models/attribute_change'

module Historical
  VALID_HISTORICAL_OPTIONS = [:timestamps, :except, :only, :merge]
  VALID_HISTORICAL_MERGE_OPTIONS = [:if_time_difference_is_less_than]
  TIMESTAMP_ATTRIBUTES = %w{created_at updated_at}

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
    # * <tt>timestamps</tt> - whether or not to include created_at and updated_at for versioning (default: false)
    # * <tt>merge</tt> - options for version-merging to avoid clutter (default: false)
    def historical(options = {})
      options = {:timestamps => false, :only => false, :except => false}.merge(options)
      validate_historical_options(options)
      validate_historical_merge_options(options[:merge])
      
      send :include, InstanceMethods
      
      cattr_accessor :historical_merge_options
      self.historical_merge_options = options[:merge]
      
      has_many :versions, :as => :target, :dependent => :destroy
      has_many :attribute_changes, :through => :versions
      
      only = options[:only]
      only = Array.wrap(only).collect{ |x| x.to_s } if only
      
      except = options[:except]
      except = Array.wrap(except).collect{ |x| x.to_s } if except
      
      raise "You can't use :only and :except at the same time" if only and except
      
      after_update do |model|
        next unless model.changed? and model.changes
        
        changes = model.changes.reject do |k,v|
          if only
            !only.include? k
          elsif except and except.include? k
            true
          elsif !options[:timestamps]
            TIMESTAMP_ATTRIBUTES.include? k
          else
            false
          end
        end
        
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
    def as_version(version_number)
      version_number = version_number.to_i
      raise ActiveRecord::RecordNotFound, "version number is negative" if version_number < 0
      
      fake = self.class.find(id)
      raise ActiveRecord::RecordNotFound, "version number is in the future" if version_number > fake.versions.most_recent.first.version
      
      self.class.columns.each do |col|
        # no need to join manually, because it's a has_many :through relation
        change = attribute_changes.first(:conditions => ["versions.version > ? AND attribute_changes.attribute = ?", version_number, col.name],
                                        :order => "versions.version ASC")
        fake[col.name] = change.old if change
      end
      fake.freeze
      fake.readonly!
      fake
    end
  end
end

ActiveRecord::Base.send :include, Historical
