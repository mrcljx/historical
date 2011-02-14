require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "historical"
  gem.summary = %Q{DRY and serialization-free versioning for ActiveRecord}
  gem.description = %Q{Rewrite of the original historical-plugin using MongoDB}
  gem.email = "marcel@northdocks.com"
  gem.homepage = "http://github.com/sirlantis/historical"
  gem.authors = ["Marcel Jackwerth"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
class YARD::Handlers::Ruby::Legacy::MongoHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /^(one|many|key)/

  def process
    match = statement.tokens.to_s.match(/^(one|many|key)\s+:([a-zA-Z0-9_]+)/)
    return unless match

    type, method = match[1], match[2]

    case type
    when "many"
      register(MethodObject.new(namespace, method) do |obj|
        if obj.tag(:return) && (obj.tag(:return).types || []).empty?
          obj.tag(:return).types = ['Array']
        elsif obj.tag(:return).nil?
          obj.docstring.add_tag(YARD::Tags::Tag.new(:return, "", "Array"))
        end
      end)
    else
      register MethodObject.new(namespace, method)
    end
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files   = FileList['lib/**/*.rb']
end
