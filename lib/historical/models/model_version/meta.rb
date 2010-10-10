module Historical::Models
  class ModelVersion
    # A meta model which stores additional data to each new version (could be used for audits).
    class Meta
      include MongoMapper::EmbeddedDocument
      plugin Historical::MongoMapper::SciAntidote
      plugin Historical::MongoMapper::Enhancements
      
      key :created_at, Time
      
      def created_at=(time)
        write_key :created_at, time.utc
      end
    
      # Retrieve customized class definition for a record class (e.g. TopicMeta, MessageMeta)
      # @return [Class]
      def self.for_class(source_class)
        Class.new(self)
      end
    end
  end
end