module Historical
  # Builds the customized classes for a record.
  class ClassBuilder
    # @return [Array<Proc>] A list of callbacks to be evaluated on save.
    # @private
    attr_accessor :callbacks
    
    # @return [Class] A customized subclass of {Models::ModelVersion::Meta}
    # @private
    attr_accessor :meta_class
    
    # @return [Class] A customized subclass of {Models::ModelVersion::Diff}
    # @private
    attr_accessor :diff_class
    
    # @return [Class] A customized subclass of {Models::ModelVersion}
    # @private
    attr_accessor :version_class
    
    # @param base The record on which the customized classes should be based on
    def initialize(base)
      self.callbacks = []
      
      self.version_class  = Historical::Models::ModelVersion.for_class(base)
      self.diff_class     = Historical::Models::ModelVersion::Diff.for_class(base)
      self.meta_class     = Historical::Models::ModelVersion::Meta.for_class(base)
      
      base.historical_customizations.each do |customization|
        self.instance_eval(&customization)
      end
    end
    
    # @group Builder Methods
    
    # Evaluated within class scope of the custom {Models::ModelVersion::Meta} for this record.
    # The Meta-class includes `MongoMapper::EmbeddedDocument` and {MongoMapperEnhancements}.
    # @example Usage within is_historical
    #   is_historical do
    #     meta do
    #       key :some_key, String
    #     end
    #   end
    def meta(&block)
      meta_class.instance_eval(&block)
    end
    
    # A callback to be called when a new version is spawned (i.e. model was saved with changes)
    # @yield [version] Your callback
    # @yieldparam [Models::ModelVersion] version The new version to be saved
    # @example Usage within is_historical
    #   is_historical do
    #     callback do |version|
    #       version.meta.some_key = "foo"
    #     end
    #   end
    def callback(&block)
      self.callbacks << block
    end
  end
end