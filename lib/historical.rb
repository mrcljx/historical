require 'models/version'
require 'models/attribute_change'

module Historical
  IGNORED_ATTRIBUTES = %w{created_at updated_at}

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def can_merge?(model, changes)
      last = model.versions.most_recent.first
      return false unless last
      last.created_at >= 2.minutes.ago
    end
  
    def historical(*args)
      send :include, InstanceMethods
      has_many :versions, :as => :target, :dependent => :destroy
      has_many :attribute_changes, :through => :versions
      
      after_update do |model|
        next unless model.changed? and model.changes
        
        changes = model.changes.reject { |k,v| IGNORED_ATTRIBUTES.include? k }
        next if changes.empty?
        
        Version.transaction do
          if can_merge?(model, changes)
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
