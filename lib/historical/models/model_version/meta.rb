module Historical::Models
  class ModelVersion
    # A meta model which stores additional data to each new version (could be used for audits).
    class Meta
      include MongoMapper::EmbeddedDocument
      extend Historical::MongoMapperEnhancements
      
      key :created_at, Time
    
      # Retrieve customized class definition for a record class (e.g. TopicMeta, MessageMeta)
      # @return [Class]
      def self.for_class(source_class)
        Historical::Models::Pool.pooled(Historical::Models::Pool.pooled_name(source_class, self)) do
          Class.new(self)
        end
      end
    end
  end
end