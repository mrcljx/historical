require 'historical'
require 'rails'

module Historical
  class Railtie < Rails::Railtie
    config.after_initialize do
      ActiveRecord::Base.send(:extend, Historical::ActiveRecord)
    end
  end
end
