module HistoricalTestModels
  class MergeablePost < ActiveRecord::Base
    set_table_name :posts
    
    is_historical :merge => { :if_time_difference_is_less_than => 2.minutes }
    
    belongs_to :author, :class_name => "HistoricalTestModels::Person"
  end

  class Post < ActiveRecord::Base
    set_table_name :posts
    
    is_historical
    
    belongs_to :author, :class_name => "HistoricalTestModels::Person"
  end
end