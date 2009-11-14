module HistoricalTestModels
  class Person < ActiveRecord::Base
    is_historical :only => :email
  end
end