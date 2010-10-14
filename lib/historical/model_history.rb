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
        
        if Historical.autospawn_creation and version_count.zero?
          assert_creation!
          version_count = 1
        end
        
        @base_version = version_count - 1
      end
    end
    
    # Destroys the complete history (i.e. all versions) of this model. The model itself will remain untouched.
    def destroy
      versions.remove
      record.invalidate_history! if record.history == self
    end
  
    # @return [Array<Models::ModelVersion>] All versions of this model (oldest first).
    def versions
      Models::ModelVersion.for_record(record).sort(:"meta.created_at".asc, :_id.asc)
    end
    
    delegate :version_index, :to => :own_version
    
    # @return [Models::ModelVersion] The own version
    def own_version
      versions.skip(@base_version).limit(1).first.tap do |own|
        raise "couldn't find myself (base_version: #{@base_version}, versions: #{versions.count})" unless own
      end
    end
    
    # @return [Models::ModelVersion] The immediate predecessor
    def previous_version
      own_version.previous
    end
    
    # @return [Models::ModelVersion] The immediate successor
    def next_version
      own_version.next
    end
  
    # @return [Models::ModelVersion] The latest version
    def latest_version
      versions.last
    end
  
    # @return [Models::ModelVersion] The first (i.e. original) version
    def original_version
      versions.first
    end
  
    # @return [Models::ModelVersion] The creation version (should be the {#original_version}).
    def creation
      @creation ||= versions.where(:"meta.creation" => true).first
    end
  
    # @return [Models::ModelVersion] The update versions (every version except the {#creation}).
    def updates
      versions.where(:"meta.creation" => false)
    end
    
    # @param [Integer] position The index of the version to be found (zero-based).
    # @return [Models::ModelVersion, nil] The found version or nil.
    def find_version(position)
      versions.skip(position).limit(1).first
    end
    
    # Finds a version.
    # @return [Models::ModelVersion, nil]
    # @overload version_by_query(index)
    #   Like {#find_version}.
    #   @param [Integer] index The index of the version to be found (zero-based). 
    #   @return [Models::ModelVersion]
    # @overload version_by_query(relation)
    #   Finds a relative version.
    #   @param [:first, :creation, :latest, :next, :previous] relation The relation of the version to be found to the current version.
    #   @return [Models::ModelVersion]
    def version_by_query(query)
      case query
      when Numeric                then find_version(query)
      when Symbol                 then send(query)
      when Models::ModelVersion   then query
      else
        nil
      end
    end
    
    # Restores a model.
    # @param query A query like in {#version_by_query}
    # @return [Object] A frozen instance of the model in it's earlier state.
    def restore(query)
      version = version_by_query(query)
      raise ::ActiveRecord::RecordNotFound, "version (base_version: #{base_version}, query: #{query}) does not exist" unless version
      version.restore(record)
    end
    
    # Some helpers
    %w(original latest previous next).each do |k|
      alias_method k, "#{k}_version"
    end
    
    # Makes sure that we have a creation of this model.
    def assert_creation!(&block)
      spawn_creation!(&block) unless creation
    end
    
    protected
    
    # Spawns a creation version for this model.
    # @private
    def spawn_creation!
      record.send(:spawn_version, :create).tap do |c|
        c.meta.created_at = record.created_at
        yield(c) if block_given?
        c.save!
        @creation = c
      end
    end
  end
end