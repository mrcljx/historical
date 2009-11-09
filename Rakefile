require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "historical"
    gem.summary = %q{Yet another versioning plugin for Rails' ActiveRecord}
    gem.description = %q{Yet another versioning plugin for Rails' ActiveRecord}
    gem.email = "marcel@northdocks.com"
    gem.homepage = "http://github.com/sirlantis/historical"
    gem.authors = ["Marcel Jackwerth"]
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

desc 'Generate documentation for the historical plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Historical'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
