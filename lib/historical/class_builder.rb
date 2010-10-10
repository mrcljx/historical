module Historical
  # Builds the customized classes for a record.
  class ClassBuilder
    
    # @return [Class] The class for which customized versions should be generated.
    # @private
    attr_reader :base
    
    # @return [Array<Proc>] A list of callbacks to be evaluated on save.
    # @private
    attr_reader :callbacks
    
    # @return [Class] A customized subclass of {Models::ModelVersion::Meta}
    # @private
    attr_reader :meta_class
    
    # @return [Class] A customized subclass of {Models::ModelVersion::Diff}
    # @private
    attr_reader :diff_class
    
    # @return [Class] A customized subclass of {Models::ModelVersion}
    # @private
    attr_reader :version_class
    
    # @param base The record on which the customized classes should be based on
    def initialize(base)
      @base = base
      @callbacks = []
      
      @diff_class = Historical::Models::ModelVersion::Diff.for_class(base).tap do |c|
        base.const_set "ModelVersionDiff",  c
        base.historical_diff_class =        c
      end
      
      @meta_class = Historical::Models::ModelVersion::Meta.for_class(base).tap do |c|
        base.const_set "ModelVersionMeta",  c
        base.historical_meta_class =        c
      end
      
      @version_class = Historical::Models::ModelVersion.for_class(base).tap do |c|
        base.const_set "ModelVersion",  c
        base.historical_version_class = c
      end
      
      base.historical_customizations.each do |customization|
        instance_eval(&customization)
      end
      
      [diff_class, meta_class, version_class].each { |c| c.unloadable }
    end
    
    def apply!
      base.historical_callbacks     ||= []
      base.historical_callbacks     += callbacks
      base
    end
    
    # @group Builder Methods
    
    # Evaluated within class scope of the custom {Models::ModelVersion::Meta} for this record.
    # The Meta-class includes `MongoMapper::EmbeddedDocument` and {MongoMapper::Enhancements}.
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