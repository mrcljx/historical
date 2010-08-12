module Historical::Models
  class ModelDiff
    include MongoMapper::Document
  
    IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]

    validates_associated :changes

    key :record_id,   Integer,  :required => true
    key :record_type, String,   :required => true
  
    key :diff_type,   String,   :required => true
    key :type,        String
  
    timestamps!

    belongs_to :new_version, :class_name => "Historical::Models::ModelVersion", :required => true
  
    def old_version
      new_version.previous
    end
  
    many :changes, :class_name => "Historical::Models::AttributeDiff"

    def record
      record_type.constantize.find(record_id)
    end

    def self.from_versions(from, to)
      return from_creation(to) if from.nil?

      generate_from_version(from, 'update').tap do |d|
        from.record.attribute_names.each do |attr_name|
          attr = attr_name.to_sym
          next if IGNORED_ATTRIBUTES.include? attr
    
          old_value, new_value = from[attr], to[attr]
         
          Historical::Models::AttributeDiff.specialized_for(d, attr).new.tap do |ad|
            ad.attribute_type = Historical::Models::AttributeDiff.detect_attribute_type(d, attr)
            ad.parent = d
            ad.old_value = old_value
            ad.new_value = new_value
            ad.attribute = attr.to_s
            d.changes << ad
          end if old_value != new_value
        end
      
        d.save!
      end
    end

    def self.from_creation(to)
      generate_from_version(to).save!
    end
  
    protected
  
    def self.generate_from_version(version, type = 'creation')
      ModelDiff.new.tap do |d|
        d.diff_type = type
        d.type = "#{version.record_type}Diff"
        d.record_id, d.record_type = version.record_id, version.record_type
      end
    end
  end
end
