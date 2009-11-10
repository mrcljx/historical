class HistoricalMigrationGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
  
  def file_name
      "historical_migration"
    end
end
