require File.dirname(__FILE__) + '/test_helper.rb'
require 'rails_generator'
require 'rails_generator/scripts/generate'

class MigrationGeneratorTest < ActiveSupport::TestCase

  def setup
    FileUtils.mkdir_p(fake_rails_root)
    @original_files = file_list
  end

  def teardown
    FileUtils.rm_r(fake_rails_root)
  end

  should "be a valid migration" do
    Rails::Generator::Scripts::Generate.new.run(["historical_migration"], :destination => fake_rails_root, :quiet => true)
    new_file = (file_list - @original_files).first
    
    # TODO: some useful test here
  end

  private

    def fake_rails_root
      File.join(File.dirname(__FILE__), 'rails_root')
    end

    def file_list
      Dir.glob(File.join(fake_rails_root, "*"))
    end

end