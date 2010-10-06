require 'historical'
require 'rails'

module Historical
  # @private
  class Railtie < Rails::Railtie
    initializer "historical.attach_to_active_record" do
      ::ActiveRecord::Base.send(:extend, Historical::ActiveRecord)
    end
  end
end
