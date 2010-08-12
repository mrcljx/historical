module Historical::Models
  class ModelVersion
    include MongoMapper::Document

    key :record_id, Integer, :required => true
    key :record_type, String, :required => true
    timestamps!
  
    one :diff, :class_name => "Historical::Models::ModelDiff"

    def record
      record_type.constantize.find(record_id)
    end
  
    def previous
      ModelVersion.where(:record_id => record_id, :record_type => record_type, :created_at.lte => created_at, :id.ne => id).sort(:created_at.desc).first
    end
  
    def next
      ModelVersion.where(:record_id => record_id, :record_type => record_type, :created_at.gte => created_at, :id.ne => id).sort(:created_at.asc).first
    end
  end
end
