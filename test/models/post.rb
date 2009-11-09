class MergeablePost < ActiveRecord::Base
  set_table_name :posts
  
  historical :merge => { :if_time_difference_is_less_than => 2.minutes }
end

class Post < ActiveRecord::Base
  historical
end