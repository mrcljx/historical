module Historical
  module Models
    class ModelHistory
      def initialize(record)
        @record = record
      end
      
      attr_reader :record
      
      def versions
        ModelVersion.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc)
      end
      
      def diffs
        ModelDiff.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc)
      end
    end
    
    class ModelVersion
      include MongoMapper::Document
  
      key :record_id, Integer, :required => true
      key :record_type, String, :required => true
      timestamps!
  
      def record
        record_type.constantize.find(record_id)
      end
      
      def previous
        ModelVersion.where(:record_id => record_id, :record_type => record_type, :created_at.lte => created_at, :id.ne => id).sort(:created_at.desc).first
      end
      
      def next
        ModelVersion.where(:record_id => record_id, :record_type => record_type, :created_at.gte => created_at, :id.ne => id).sort(:created_at.asc).first
      end
    end

    class ModelDiff
      include MongoMapper::Document
      
      IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]
  
      key :record_id, Integer, :required => true
      key :record_type, String, :required => true
  
      key :diff_type, String, :required => true
      key :type, String
  
      one :old_version, :class_name => "Historical::Models::ModelVersion"
      one :new_version, :class_name => "Historical::Models::ModelVersion"
      
      many :changes, :class_name => "Historical::Models::AttributeDiff"
      
      timestamps!
  
      def self.from_versions(from, to)
        return from_creation(to) if from.nil?
    
        generate_from_version(from, 'update').tap do |d|
          from.record.attribute_names.each do |attr_name|
            attr = attr_name.to_sym
            next if IGNORED_ATTRIBUTES.include? attr
        
            old_value, new_value = from[attr], to[attr]
             
            AttributeDiff.new.tap do |ad|              
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
    
    class AttributeDiff
      include MongoMapper::EmbeddedDocument
      
      key :attribute, String
      key :old_value, Object
      key :new_value, Object
    end
  end
end