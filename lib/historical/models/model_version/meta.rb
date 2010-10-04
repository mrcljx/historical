module Historical::Models
  class ModelVersion
    class Meta
      include MongoMapper::EmbeddedDocument
      extend Historical::MongoMapperEnhancements
    
    
      def self.for_class(source_class)
        Historical::Models::Pool.pooled(Historical::Models::Pool.pooled_name(source_class, self)) do
          Class.new(self)
        end
      end
    end
  end
end