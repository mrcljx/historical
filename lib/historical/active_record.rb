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
    
    def is_historical
      class_eval do
        attr_accessor :historical_differences, :historical_creation
        
        # dirty attributes a removed after save, so we need to check it here
        before_update do |record|
          record.historical_differences = !record.changes.empty?
          true
        end
        
        # new_record flag is removed after save, so we need to check it here
        before_save do |record|
          record.historical_creation = record.new_record?
          true
        end
        
        after_save do |record|
          next unless record.historical_creation or record.historical_differences
          
          
          version = Historical::Models::ModelVersion.for_class(record.class).new.tap do |v|
            v._record_id    = record.id
            v._record_type  = record.class.name
            
            record.attribute_names.each do |attr_name|
              attr = attr_name.to_sym
              next if Historical::IGNORED_ATTRIBUTES.include? attr
              v.send("#{attr}=", record[attr])
            end
            
            v.save!
          end
          
          Historical::Models::ModelDiff.from_versions(version.previous, version)
        end
        
        def history
          @history ||= Historical::ModelHistory.new(self)
        end
      end
    end
  end
end