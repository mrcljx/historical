# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{historical}
  s.version = ""

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Marcel Jackwerth"]
  s.date = %q{2010-08-16}
  s.description = %q{DRY and serialization-free versioning for ActiveRecord models}
  s.email = %q{marcel@northdocks.com}
  s.files = [
    ".gitignore",
     "Rakefile",
     "lib/historical.rb",
     "rails/init.rb"
  ]
  s.homepage = %q{http://github.com/sirlantis/historical}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{DRY and serialization-free versioning for ActiveRecord models}
  s.test_files = [
    "test/assoications_test.rb",
     "test/historical_test.rb",
     "test/integration_test.rb",
     "test/merge_test.rb",
     "test/migration_generator_test.rb",
     "test/models/person.rb",
     "test/models/post.rb",
     "test/revert_test.rb",
     "test/schema.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end

