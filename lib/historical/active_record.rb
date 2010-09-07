module Historical
  module ActiveRecord
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
    
    def is_historical(&block)
      class_eval do
        cattr_accessor :historical_customizations, :historical_installed
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
            
            v.diff = Historical::Models::ModelDiff.from_versions(v.previous, v, mode != :create)
            v.save!
          end
        end
      end
      
      self.historical_installed         = true
      self.historical_customizations    ||= []
      self.historical_customizations    << block if block_given?
      
      # generate pooled classes
      Historical::Models::ModelDiff.for_class(self)
      Historical::Models::ModelVersion.for_class(self)
    end
  end
end