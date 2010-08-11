$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'historical'
require 'spec'
require 'spec/autorun'

require 'rubygems'

gem "rails", "= 2.3.8"

require 'active_support'
require 'active_support/test_case'
require 'active_record'
require 'mongo_mapper'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :messages do |t|
    t.string :title
    t.text   :body
  end
end

MongoMapper.database = "historical-test"
MongoMapper.database.collections.each(&:remove)

Spec::Runner.configure do |config|
  
end
