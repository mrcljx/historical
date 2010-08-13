module Historical::Models
  module Pool
    # cached classes are stored here
  end
  
  class ModelVersion
    include MongoMapper::Document

    key :_type,           String
    key :_record_id,      Integer,  :required => true
    key :_record_type,    String,   :required => true
    timestamps!
  
    one :diff, :class_name => "Historical::Models::ModelDiff"

    def record
      record_class.find(_record_id)
    end
    
    def record_class
      _record_type.constantize
    end
  
    def previous
      self.class.for_record(_record_id, _record_type).where(:created_at.lte => created_at, :_id.ne => id).sort(:created_at.desc).first
    end
  
    def next
      self.class.for_record(_record_id, _record_type).where(:created_at.gte => created_at, :_id.ne => id).sort(:created_at.asc).first
    end
    
    def self.for_record(record_or_id, type = nil)
      if type
        ModelVersion.where(:_record_id => record_or_id, :_record_type => type)
      else
        ModelVersion.where(:_record_id => record_or_id.id, :_record_type => record_or_id.class.name)
      end
    end
    
    def self.for_class(source_class)
      @@class_pool ||= {}
      return @@class_pool[source_class] if @@class_pool[source_class]
      
      Class.new(ModelVersion).tap do |cls|
        source_class.columns.each do |col|
          next if Historical::IGNORED_ATTRIBUTES.include? col.name.to_sym
          type = Historical::ActiveRecord.sql_to_type(col.type)
          cls.send :key, col.name, type.constantize
        end
        
        Historical::Models::Pool::const_set(pooled_class_name(source_class), cls)
        @@class_pool[source_class] = cls
      end
    end
    
    def self.pooled_class_name(source_class)
      "#{source_class.name.demodulize}#{self.name.demodulize}"
    end
  end
end
