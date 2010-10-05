module Historical
  class ModelHistory
    attr_reader :record, :base_version
    
    def initialize(record)
      @record = record
      
      if record.historical_version
        @base_version = record.historical_version
      elsif record.new_record?
        @base_version = -1
      else
        version_count = versions.count
        
        if version_count.zero?
          spawn_creation!
          version_count = 1
        end
        
        @base_version = version_count - 1
      end
    end
    
    def destroy
      versions.remove
      record.history = nil if record.history == self
    end
  
    def versions
      Models::ModelVersion.for_record(record).sort(:"meta.created_at".asc, :_id.asc)
    end
    
    delegate :version_index, :to => :own_version
    
    def own_version
      versions.skip(@base_version).limit(1).first.tap do |own|
        raise "couldn't find myself (base_version: #{@base_version}, versions: #{versions.count})" unless own
      end
    end
    
    def previous_version
      own_version.previous
    end
    
    def next_version
      own_version.next
    end
  
    def latest_version
      versions.last
    end
  
    def original_version
      versions.first
    end
  
    def creation
      versions.where("diff.diff_type" => "creation").first
    end
  
    def updates
      versions.where("diff.diff_type" => "update")
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
    
    def restore(query)
      version = version_by_query(query)
      raise ::ActiveRecord::RecordNotFound, "version (base_version: #{base_version}, query: #{query}) does not exist" unless version
      version.restore(record)
    end
    
    %w(original latest previous next).each do |k|
      alias_method k, "#{k}_version"
    end
    
    protected
    
    def spawn_creation!
      record.send(:spawn_version, :create).tap do |e|
        e.created_at = record.created_at
        e.save!
      end
    end
  end
end