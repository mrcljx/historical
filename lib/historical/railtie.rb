require 'historical'
require 'rails'

module Historical
  # The railtie to be loaded by Rails.
  class Railtie < Rails::Railtie
    initializer "historical.attach_to_active_record" do
      ::ActiveRecord::Base.send(:extend, Historical::ActiveRecord)
    end

    initializer "historical.create_classes" do
      ::ActiveSupport.on_load :after_initialize do
        Historical.reset!
        Historical.boot!
      end
    end
  end
end
