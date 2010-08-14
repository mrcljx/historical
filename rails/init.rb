require File.join(File.dirname(__FILE__), '..', 'lib', 'historical')

ActiveRecord::Base.send(:include, Historical::ActiveRecord)
