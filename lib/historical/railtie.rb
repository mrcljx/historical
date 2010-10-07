require 'historical'
require 'rails'

module Historical
  # The railtie to be loaded by Rails.
  class Railtie < Rails::Railtie
    initializer "historical.attach_to_active_record" do
      ::ActiveRecord::Base.send(:extend, Historical::ActiveRecord)
    end
  end
end
