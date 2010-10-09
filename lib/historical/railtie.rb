require 'historical'
require 'rails'

module Historical
  # The railtie to be loaded by Rails.
  class Railtie < Rails::Railtie
    initializer "historical.attach_to_active_record" do
      ::ActiveRecord::Base.send(:extend, Historical::ActiveRecord)
    end
    
    config.to_prepare do
      Historical::Models::Pool.clear!
      Historical.boot!
    end
  end
end
