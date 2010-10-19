module Historical
  module ActiveRecord
    # converts database fieldtypes to Ruby types
    def self.sql_to_type(type)
      case type.to_sym
      when :datetime then "Time"
      when :text then "String"
      when :decimal then "Float"
      when :timestamp then "Time"
      else
        type.to_s.classify
      end
    end
    
    # Extensions for a model that is flagged as `is_historical`.
    module Extensions
      extend ActiveSupport::Concern
      
      included do
        cattr_accessor :historical_customizations, :historical_callbacks, :historical_installed
        cattr_accessor :historical_meta_class, :historical_version_class, :historical_diff_class
        
        attr_accessor :historical_differences, :historical_creation, :historical_version
        attr_accessor :spawned_version
        
        before_save :detect_version_spawn
        after_save :invalidate_history!
        after_save :spawn_version, :if => :spawn_version?
        
        attr_writer :history
      end
      
      module ClassMethods
        # Generates the customized classes ({Models::ModelVersion}, {Models::ModelVersion::Meta}, {Models::ModelVersion::Diff}) for this model.
        def generate_historical_models!
          return if historical_version_class
          builder = Historical::ClassBuilder.new(self)
          builder.apply!
        end
      end
      
      module InstanceMethods
        # @return [ModelHistory] The history of this model
        def history
          @history ||= Historical::ModelHistory.new(self)
        end
        
        # @return [Integer] The version number of this model
        def version
          historical_version || history.own_version.version_index
        end
        
        # Invalidates the history of that model
        # @private
        def invalidate_history!
          @history = nil
        end
        
        protected
        
        # Set some flags before saving the model (so that after_save-callbacks can be run)
        # @private
        def detect_version_spawn
          if new_record?
            self.historical_creation = true
            self.historical_differences = []
          else
            self.historical_creation = false
            self.historical_differences = (changes.empty? ? nil : changes)
          end
          
          true
        end
        
        # Check whether a new version should be spawned (also see {detect_version_spawn})
        # @private
        def spawn_version?
          historical_creation or historical_differences
        end
        
        # Spawns a new version
        # @private
        def spawn_version(mode = :update)
          mode = :create if historical_creation
          
          version = self.class.historical_version_class.new
          version.tap do |v|
            v._record_id    = id
            v._record_type  = self.class.name
            
            attribute_names.each do |attr_name|
              attr = attr_name.to_sym
              next if Historical::IGNORED_ATTRIBUTES.include? attr
              v.send("#{attr}=", self[attr])
            end
            
            v.meta = self.class.historical_meta_class.new.tap do |m|
              m.creation = (mode == :create)
              m.created_at = Time.now
            end
            
            v.diff = self.class.historical_diff_class.from_versions(v.previous, v) unless v.creation?
            
            (self.class.historical_callbacks || []).each do |callback|
              callback.call(v)
            end
            
            v.save!
            
            self.spawned_version = v
          end
        end
      end
    end
  
    # Enables Historical in this model.
    #
    # @example simple
    #   class Message < ActiveRecord::Base
    #     is_historical
    #   end
    #
    # @example advanced, with custom meta-data (auditing)
    #   class Message < ActiveRecord::Base
    #     is_historical do
    #       meta do
    #         belongs_to_active_record :user
    #         key :cause, String
    #       end
    #     
    #       callback do |version|
    #         version.meta.cause  = "just because"
    #         version.meta.user   = App.current_user
    #       end
    #     end
    #   end
    def is_historical(&block)
      return if respond_to?(:historical_installed) and historical_installed
      
      include Historical::ActiveRecord::Extensions
      
      self.historical_installed         = true
      self.historical_customizations    ||= []
      self.historical_customizations    << block if block_given?
      
      Historical.register(self)
    end
  end
end