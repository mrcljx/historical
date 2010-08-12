module Historical
  module ActiveRecord
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
          
          version = Historical::Models::ModelVersion.new.tap do |v|
            v.record_id, v.record_type = record.id, record.class.name
            
            record.attribute_names.each do |attr_name|
              attr = attr_name.to_sym
              next if Historical::Models::ModelDiff::IGNORED_ATTRIBUTES.include? attr
              v[attr] = record[attr]
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