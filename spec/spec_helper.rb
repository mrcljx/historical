$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'historical'
require 'spec'
require 'spec/autorun'

require 'rubygems'

gem "rails", ">= 3.0.0"

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
      t.integer   :votes,         :default => 0
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

    execute "
      INSERT INTO
        messages (id, title, body, created_at, updated_at)
      VALUES
        (1, 'existed already', 'hi', '2010-01-01 00:00:00', '2010-01-01 00:00:00')"
  end
end

config = YAML::load(File.read(File.join(File.dirname(__FILE__), 'mongo_mapper.yml')))["test"]

mongodb = nil
if config["standalone"]
  mongodb = fork do
    puts "Launching standalone MongoDB"
    config_path = File.join(File.dirname(__FILE__), 'standalone.conf')
    dbpath = File.join(File.dirname(__FILE__), '..', 'tmp/db')
    `rm -rf #{dbpath}`
    `mkdir -p #{dbpath}`
    exec "mongod --port #{config["port"]} --noprealloc --dbpath #{dbpath} --pidfilepath #{dbpath} --config #{config_path} > /dev/null 2>&1"
  end

  puts "Waiting for MongoDB to start"
  sleep 3
end

MongoMapper.connection = Mongo::Connection.new(config["host"], config["port"])
MongoMapper.database = config["database"]
MongoMapper.database.collections.each(&:remove)

Spec::Runner.configure do |config|

end

at_exit do
  if mongodb
    puts "Killing standalone MongoDB (pid:#{mongodb})"
    Process.kill("KILL", mongodb)
    puts "Killed."
  end
end