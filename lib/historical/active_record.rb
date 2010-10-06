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
      class_eval do
        cattr_accessor :historical_customizations, :historical_callbacks, :historical_installed
        cattr_accessor :historical_meta_class, :historical_version_class, :historical_diff_class
        
        attr_accessor :historical_differences, :historical_creation, :historical_version
        
        before_save :detect_version_spawn
        after_save :invalidate_history
        after_save :spawn_version, :if => :spawn_version?
        
        attr_writer :history
        
        def history
          @history ||= Historical::ModelHistory.new(self)
        end
        
        def version
          historical_version || history.own_version.version_index
        end
        
        protected
        
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
        
        def invalidate_history
          self.history = nil
        end
        
        def spawn_version?
          historical_creation or historical_differences
        end
        
        def spawn_version(mode = :update)
          mode = :create if historical_creation
          
          Historical::Models::ModelVersion.for_class(self.class).new.tap do |v|
            v._record_id    = id
            v._record_type  = self.class.name
            
            
            attribute_names.each do |attr_name|
              attr = attr_name.to_sym
              next if Historical::IGNORED_ATTRIBUTES.include? attr
              v.send("#{attr}=", self[attr])
            end
            
            previous  = (mode != :create ? v.previous : nil)
            
            v.diff    = Historical::Models::ModelVersion::Diff.from_versions(previous, v)
            v.meta    = self.class.historical_meta_class.new
            
            (self.class.historical_callbacks || []).each do |callback|
              callback.call(v)
            end
            
            v.save!
          end
        end
        
        def self.generate_historical_models!
          builder = Historical::ClassBuilder.new(self)

          self.historical_callbacks     ||= []
          self.historical_callbacks     += builder.callbacks

          self.historical_version_class = builder.version_class
          self.historical_meta_class    = builder.meta_class
          self.historical_diff_class    = builder.diff_class
        end
      end
      
      self.historical_installed         = true
      self.historical_customizations    ||= []
      self.historical_customizations    << block if block_given?
      
      Historical.historical_models      << self
    end
  end
end