module Historical
  class ModelHistory
    def initialize(record)
      @record = record
    end
  
    attr_reader :record
  
    def versions
      Models::ModelVersion.where(:_record_id => record.id, :_record_type => record.class.name).sort(:created_at.asc, :id.asc)
    end
  
    def diffs
      Models::ModelDiff.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc, :id.asc)
    end
  
    def latest_version
      versions.last
    end
  
    def original_version
      versions.first
    end
  
    def creation
      diffs.where(:diff_type => "creation").first
    end
  
    def updates
      diffs.where(:diff_type => "update")
    end
  end
end