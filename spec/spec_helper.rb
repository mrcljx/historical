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
ActiveRecord::Base.logger ||= Logger.new(STDOUT)  
ActiveRecord::Base.logger.level = Logger::WARN

ActiveRecord::Base.silence do
  ActiveRecord::Schema.define(:version => 1) do
    self.verbose = false
    
    create_table :messages do |t|
      t.string    :title
      t.text      :body
      t.integer   :votes
      t.datetime  :published_at
      t.date      :stamped_on
      t.decimal   :donated,       :precision => 10, :scale => 2
      t.boolean   :read,          :null => false, :default => false
      t.timestamps
    end
    
    create_table :users do |t|
      t.string :name
      t.timestamps
    end
  end
end

MongoMapper.database = "historical-test"
MongoMapper.database.collections.each(&:remove)

Spec::Runner.configure do |config|
  
end
