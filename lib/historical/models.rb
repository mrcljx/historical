module Historical
  module Models
    class ModelHistory
      def initialize(record)
        @record = record
      end
      
      attr_reader :record
      
      def versions
        ModelVersion.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc, :id.asc)
      end
      
      def diffs
        ModelDiff.where(:record_id => record.id, :record_type => record.class.name).sort(:created_at.asc, :id.asc)
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
    end
    
    class ModelVersion
      include MongoMapper::Document
  
      key :record_id, Integer, :required => true
      key :record_type, String, :required => true
      timestamps!
      
      one :diff, :class_name => "Historical::Models::ModelDiff"
  
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
             
            AttributeDiff.new.tap do |ad|              
              ad.old_value = old_value
              ad.new_value = new_value
              ad.attribute = attr.to_s
              ad.attribute_type = AttributeDiff.detect_attribute_type(d, attr)
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
      
      key :attribute,       String, :required => true
      key :attribute_type,  String, :required => true
      key :_old_value,      Object
      key :_new_value,      Object
      
      alias :old_value :_old_value
      alias :new_value :_new_value
      
      validate :check_attribute_type
      
      def old_value=(value)
        self._old_value = value
      end
      
      def new_value=(value)
        self._new_value = value
      end
      
      def self.detect_attribute_type(parent, attribute)
        column = parent.record.class.columns.select do |c|
          c.name.to_s == attribute.to_s
        end.first
        
        column ? column.type.to_s : nil
      end
      
      protected :_old_value=, :_new_value=, :_old_value, :_new_value
      
      def check_attribute_type
        #errors.add(:attribute_type, :not_set)
      end
    end
  end
end