module HistoricalTestModels
  class Person < ActiveRecord::Base
    historical :only => :email
  end
end