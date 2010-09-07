module Historical
  class ModelHistory
    attr_reader :record
    
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
      Models::ModelVersion.for_record(record).sort(:created_at.asc, :id.asc)
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
    
    def restore(version_query)
      version = version_by_query(version_query)
      
      raise ::ActiveRecord::RecordNotFound, "version does not exist" unless version
      
      record.clone.tap do |r|
        r.id = record.id
        
        r.class.columns.each do |c|
          attr = c.name.to_sym
          next if Historical::IGNORED_ATTRIBUTES.include? attr
          
          r[attr] = version.send(attr)
        end
        
        r.historical_version = version.version_index
        r.clear_association_cache
        r.history = nil
      end
    end
    
    def restore_with_protection(*args)
      restore_without_protection(*args).tap do |r|
        r.readonly!
      end
    end
    
    alias_method_chain :restore, :protection
    
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