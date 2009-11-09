class Account < ActiveRecord::Base
  historical :except => :password, :timestamps => true
end