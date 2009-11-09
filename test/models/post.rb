class Post < ActiveRecord::Base
  historical :merge => { :if_time_difference_is_less_than => 2.minutes }
end