require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "historical"
    gem.summary = %q{DRY and serialization-free versioning for ActiveRecord models}
    gem.description = %q{DRY and serialization-free versioning for ActiveRecord models}
    gem.email = "marcel@northdocks.com"
    gem.homepage = "http://github.com/sirlantis/historical"
    gem.authors = ["Marcel Jackwerth"]
    
    gem.add_development_dependency 'shoulda'
    gem.add_development_dependency 'mocha'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

# check dependencies
task :test => :check_dependencies

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the historical plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Lists all tests.'
task :"shoulda:list" do |t|
  require 'shoulda/tasks'
  Rake::Task[:"shoulda:list"].invoke
end

desc 'Generate documentation for the historical plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Historical'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
