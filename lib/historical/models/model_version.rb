module Historical::Models
  # A complete snapshot of a model.
  class ModelVersion
    autoload :Diff, 'historical/models/model_version/diff'
    autoload :Meta, 'historical/models/model_version/meta'
    
    include MongoMapper::Document
    extend Historical::MongoMapperEnhancements
    
    validate :validate_diff
    validate :validate_meta
    
    validates_presence_of :meta

    key :_type,           String
    
    belongs_to_active_record :_record, :polymorphic => true, :required => true

    # The diff between the current and the previous version (if exists)
    # @return [Diff]
    one :diff, :class_name => "Historical::Models::ModelVersion::Diff"
    
    # The meta-data associated with the diff (i.e. this version)
    # @return [Meta]
    one :meta, :class_name => "Historical::Models::ModelVersion::Meta"
    
    before_save :update_timestamps
    
    alias_method :record, :_record
  
    # All other versions of the associated record
    def siblings
      self.class.for_record(_record_id, _record_type)
    end
  
    # All the previous versions (immediate predecessor first)
    def previous_versions
      (new? ? siblings : siblings.where(:"meta.created_at".lte => created_at, :_id.lt => _id)).sort(:"meta.created_at".desc, :_id.desc)
    end
  
    # The immediate predecessor version
    def previous
      previous_versions.first
    end
  
    # All the next versions (immediate successor first)
    def next_versions
      siblings.where(:"meta.created_at".gte => created_at, :_id.gt => _id).sort(:"meta.created_at".asc, :_id.asc)
    end
  
    # The immediate successor version
    def next
      next_versions.first
    end
    
    # The current version index (zero-based)
    def version_index
      previous_versions.count
    end
    
    # Restores the current version.
    # @param base A reference to the record (to reduce DB queries)
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
    
    # Prevents the restored version from being saved or modifed.
    def restore_with_protection(*args)
      restore_without_protection(*args).tap do |r|
        r.readonly!
      end
    end
    
    alias_method_chain :restore, :protection
    
    # Return all versions for the provided record
    # @param record_or_id [Record,Integer] The id of the record (or a record - then type can be left nil)
    # @param type [String] The type of the record
    def self.for_record(record_or_id, type = nil)
      if type
        ModelVersion.where(:_record_id => record_or_id, :_record_type => type)
      else
        ModelVersion.where(:_record_id => record_or_id.id, :_record_type => record_or_id.class.name)
      end
    end
    
    # Retrieve customized class definition for a record class (e.g. TopicVersion, MessageVersion)
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
