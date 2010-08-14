module Historical
  IGNORED_ATTRIBUTES = [:id, :created_at, :updated_at]
  
  autoload :ModelHistory, "lib/historical/model_history"
  autoload :ActiveRecord, "lib/historical/active_record"
  
  module Models
    autoload :AttributeDiff,  'lib/historical/models/attribute_diff'
    autoload :ModelDiff,      'lib/historical/models/model_diff'
    autoload :ModelVersion,   'lib/historical/models/model_version'
  end
end