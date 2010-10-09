module Historical::Models
  # A complete snapshot of a model.
  class ModelVersion
    autoload :Diff, 'historical/models/model_version/diff'
    autoload :Meta, 'historical/models/model_version/meta'
    
    include MongoMapper::Document
    plugin Historical::MongoMapper::SciAntidote
    plugin Historical::MongoMapper::Enhancements

    validate :validate_diff
    validate :validate_meta
    
    validates_presence_of :meta
    
    belongs_to_active_record :_record, :polymorphic => true, :required => true

    # The diff between the current and the previous version (if exists)
    # @return [Diff]
    attr_reader :diff
    
    # The meta-data associated with the diff (i.e. this version)
    # @return [Meta]
    attr_reader :meta
    
    before_save :update_timestamps
    
    alias_method :record, :_record
  
    # @return [Array<ModelVersion>] All other versions of the associated record
    def siblings
      self.class.for_record(_record_id, _record_type)
    end
  
    # @return [ModelVersion] All the previous versions (immediate predecessor first)
    def previous_versions
      (new? ? siblings : siblings.where(:"meta.created_at".lte => created_at, :_id.lt => _id)).sort(:"meta.created_at".desc, :_id.desc)
    end
  
    # @return [ModelVersion] The immediate predecessor version
    def previous
      previous_versions.first
    end
  
    # @return [Array<ModelVersion>] All the next versions (immediate successor first)
    def next_versions
      siblings.where(:"meta.created_at".gte => created_at, :_id.gt => _id).sort(:"meta.created_at".asc, :_id.asc)
    end
  
    # @return [ModelVersion] The immediate successor version
    def next
      next_versions.first
    end
    
    # @return [Integer] The current version index (zero-based)
    def version_index
      previous_versions.count
    end
    
    # Restores the current version.
    # @param base A reference to the record (to reduce DB queries)
    # @return [Object] The restored version.
    def restore(base = nil)
      base ||= record
      
      base.clone.tap do |r|
        r.class.columns.each do |c|
          attr = c.name.to_sym
          next if Historical::IGNORED_ATTRIBUTES.include? attr
          
          r[attr] = send(attr)
        end
        
        r.id = base.id
        r.historical_version = version_index
        r.clear_association_cache
        r.invalidate_history!
      end
    end
    
    # Prevents the restored version from being saved or modifed
    # @return [Object] A frozen instance of {#restore}
    def restore_with_protection(*args)
      restore_without_protection(*args).tap do |r|
        r.readonly!
      end
    end
    
    alias_method_chain :restore, :protection
    
    # @return [Array<ModelVersion>] All versions for the provided record
    # @overload for_record(id, type)
    #   @param id [Integer] The id of the record
    #   @param type [String] The type of the record
    #   @return [Array<ModelVersion>]
    # @overload for_record(record)
    #   @param record [Object] The record itself
    #   @return [Array<ModelVersion>]
    def self.for_record(record_or_id, type = nil)
      if type
        ModelVersion.where(:_record_id => record_or_id, :_record_type => type)
      else
        ModelVersion.where(:_record_id => record_or_id.id, :_record_type => record_or_id.class.name)
      end
    end
    
    # @return [Class] Customized class definition for a record class (e.g. TopicVersion, MessageVersion).
    def self.for_class(source_class)
      Historical::Models::Pool.pooled(Historical::Models::Pool.pooled_name(source_class, self)) do
        Class.new(self).tap do |cls|
          source_class.columns.each do |col|
            next if Historical::IGNORED_ATTRIBUTES.include? col.name.to_sym
            type = Historical::ActiveRecord.sql_to_type(col.type)
            cls.send :key, col.name, type.constantize
          end
          
          diff_class_name = Historical::Models::Pool.pooled_name(source_class, Historical::Models::ModelVersion::Diff)
          meta_class_name = Historical::Models::Pool.pooled_name(source_class, Historical::Models::ModelVersion::Meta)
          
          cls.send :one, :diff, :class_name => "Historical::Models::Pool::#{diff_class_name}"
          cls.send :one, :meta, :class_name => "Historical::Models::Pool::#{meta_class_name}"
        end
      end
    end
    
    def self.load(attrs)
      return nil if attrs.nil?
      
      if (record_type = attrs['_record_type']).present?
        class_name = Historical::Models::Pool.pooled_name(record_type, self)
        full_class_name = "Historical::Models::Pool::#{class_name}"
        full_class_name.constantize
      else
        self
      end.allocate.initialize_from_database(attrs)
    end
    
    protected
    
    # Sets the created_at timestamp in the meta model
    def update_timestamps
      if new? and !meta.created_at?
        now = Time.now.utc
        meta[:created_at] = now
      end
    end
    
    # Cascading validation for `diff`
    def validate_diff
      if diff.present? and !diff.valid?
        errors.add(:diff, "not valid")
      end
    end
    
    # Cascading validation for `meta`
    def validate_meta
      if meta.present? and !meta.valid?
        errors.add(:meta, "not valid")
      end
    end
  end
end
