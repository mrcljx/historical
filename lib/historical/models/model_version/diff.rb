module Historical::Models
  class ModelVersion
    # Contains the differences between the current and the previous version.
    class Diff
      include MongoMapper::EmbeddedDocument
      plugin Historical::MongoMapper::SciAntidote
      plugin Historical::MongoMapper::Enhancements

      validates_associated :changes

      # @return [Array<Historical::Models::AttributeDiff>]
      many  :changes,     :class_name => "Historical::Models::AttributeDiff"
  
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
        for_class(to.record.class).new.tap do |d|
          d.instance_variable_set :@parent, to
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
  
      protected
    
      # Retrieve customized class definition for a record class (e.g. TopicDiff, MessageDiff)
      # @return [Class]
      # @private
      def self.for_class(source_class)
        Class.new(self)
      end
    end
  end
end