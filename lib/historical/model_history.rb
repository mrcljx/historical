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
    
    def find_version(position)
      versions.skip(position).limit(1).first
    end
    
    def restore(version)
      version = find_version(version) if version.is_a? Numeric
      raise ::ActiveRecord::RecordNotFound, "version does not exist" unless version
      
      record.clone.tap do |r|
        r.class.columns.each do |c|
          attr = c.name.to_sym
          next if Historical::IGNORED_ATTRIBUTES.include? attr
          
          r[attr] = version.send(attr)
        end
        
        r.readonly!
        r.clear_association_cache
      end
    end
  end
end