module Historical::Models  
  class ModelVersion
    include MongoMapper::Document
    extend Historical::MongoMapperEnhancements
    
    validate :validate_diff

    key :_type,           String
    
    belongs_to_active_record :_record, :polymorphic => true, :required => true
    
    timestamps!
  
    one :diff, :class_name => "Historical::Models::ModelDiff"
    
    alias_method :record, :_record
  
    def previous_versions
      self.class.for_record(_record_id, _record_type).where(:created_at.lte => created_at, :_id.lt => _id).sort(:created_at.desc)
    end
  
    def previous
      previous_versions.first
    end
  
    def next_versions
      self.class.for_record(_record_id, _record_type).where(:created_at.gte => created_at, :_id.gt => _id).sort(:created_at.asc)
    end
  
    def next
      next_versions.first
    end
    
    def version_index
      previous_versions.count
    end
    
    def self.for_record(record_or_id, type = nil)
      if type
        ModelVersion.where(:_record_id => record_or_id, :_record_type => type)
      else
        ModelVersion.where(:_record_id => record_or_id.id, :_record_type => record_or_id.class.name)
      end
    end
    
    def self.for_class(source_class)
      Historical::Models::Pool.pooled(Historical::Models::Pool.pooled_name(source_class, self)) do
        Class.new(self).tap do |cls|
          source_class.columns.each do |col|
            next if Historical::IGNORED_ATTRIBUTES.include? col.name.to_sym
            type = Historical::ActiveRecord.sql_to_type(col.type)
            cls.send :key, col.name, type.constantize
          end
        end
      end
    end
    
    protected
    
    def validate_diff
      if diff.present? and !diff.valid?
        errors.add(:diff, "not valid")
      end
    end
  end
end
