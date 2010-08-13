module Historical
  class ModelHistory
    attr_reader :record
    
    def initialize(record)
      @record = record
      @base_version = record.historical_version
      #@base_version ||= versions.count - 1
    end
  
    def versions
      Models::ModelVersion.where(:_record_id => record.id, :_record_type => record.class.name).sort(:created_at.asc, :id.asc)
    end
  
    def diffs
      Models::ModelDiff.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc, :id.asc)
    end
    
    def previous_version
      nil
    end
    
    def next_version
      nil
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
    
    def version_by_query(query)
      case query
      when Numeric                then find_version(query)
      when Symbol                 then send(query)
      when Models::ModelVersion   then query
      else
        nil
      end
    end
    
    def restore(version_query)
      version = version_by_query(version_query)
      
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
    
    %w(original latest previous next).each do |k|
      alias_method k, "#{k}_version"
    end
  end
end