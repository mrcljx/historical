module Historical
  class ClassBuilder
    attr_accessor :callbacks
    attr_accessor :meta_class, :diff_class, :version_class
    
    def initialize(base)
      self.callbacks = []
      
      self.version_class  = Historical::Models::ModelVersion.for_class(base)
      self.diff_class     = Historical::Models::ModelVersion::Diff.for_class(base)
      self.meta_class     = Historical::Models::ModelVersion::Meta.for_class(base)
      
      base.historical_customizations.each do |customization|
        self.instance_eval(&customization)
      end
    end
    
    # builder methods
    
    def meta(&block)
      meta_class.instance_eval(&block)
    end
    
    def callback(&block)
      self.callbacks << block
    end
  end
end