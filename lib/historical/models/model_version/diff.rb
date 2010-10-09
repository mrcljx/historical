module Historical::Models
  class ModelVersion
    # Contains the differences between the current and the previous version.
    class Diff
      include MongoMapper::EmbeddedDocument
      plugin Historical::MongoMapper::SciAntidote
      plugin Historical::MongoMapper::Enhancements

      validates_associated :changes

      key   :diff_type,   String,   :required => true
      
      # @return [Array<Historical::Models::AttributeDiff>]
      many  :changes,     :class_name => "Historical::Models::AttributeDiff"
    
      delegate :creation?, :update?, :to => :diff_type_inquirer
  
      # The record the diff was applied on
      def record
        new_version.record
      end
      
      # The version after the diff was applied
      def new_version
        @parent || _parent_document
      end
  
      # The version before the diff was applied
      def old_version
        new_version.previous
      end

      # @return [Hash] The changes stored in a Hash.
      # @example Structure (:attribute => [old_value, new_value])
      #   { :topic => ["Old Topic", "New Topic"], :votes => [10, 20] }
      def to_hash
        {}.tap do |result|
          changes.each do |c|
            result[c.attribute.to_sym] = [c.old_value, c.new_value]
          end
        end
      end

      # Generates a diff from two versions.
      # @private
      def self.from_versions(from, to)
        return from_creation(to) if !from
      
        generate_from_version(from, 'update').tap do |d|
          from.record.attribute_names.each do |attr_name|
            attr = attr_name.to_sym
            next if Historical::IGNORED_ATTRIBUTES.include? attr
    
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
        end
      end

      # Generates a creation diff
      # @private
      def self.from_creation(to)
        generate_from_version(to)
      end
  
      protected
    
      # Helper to allow diff_type.create? and diff_type.update?
      # @private
      def diff_type_inquirer
        ActiveSupport::StringInquirer.new(diff_type)
      end
  
      # Generates a basic Diff instance
      # @private
      def self.generate_from_version(version, type = 'creation')
        for_class(version.record.class).new.tap do |d|
          d.diff_type   = type
          d.instance_variable_set :@parent, version
        end
      end
    
      # Retrieve customized class definition for a record class (e.g. TopicDiff, MessageDiff)
      # @return [Class]
      # @private
      def self.for_class(source_class)
        Historical::Models::Pool.pooled(Historical::Models::Pool.pooled_name(source_class, self)) do
          Class.new(self)
        end
      end
    end
  end
end