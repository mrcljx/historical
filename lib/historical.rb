module Historical
  IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]
  
  autoload :ModelHistory, "historical/model_history"
  autoload :ActiveRecord, "historical/active_record"
  
  module Models
    autoload :AttributeDiff,  'historical/models/attribute_diff'
    autoload :ModelDiff,      'historical/models/model_diff'
    autoload :ModelVersion,   'historical/models/model_version'
  end
end