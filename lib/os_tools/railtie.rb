require 'rails'
require 'active_model/railtie'

# Comment taken from active_record/railtie.rb
#
# For now, action_controller must always be present with
# rails, so let's make sure that it gets required before
# here. This is needed for correctly setting up the middleware.
# In the future, this might become an optional require.
require 'action_controller/railtie'

module OSTools
  class Railtie < Rails::Railtie

    config.before_initialize do
      OSTools.configure do |config|
        config.schema_names = []
      end
    end

    rake_tasks do
      load 'os_tools/railties/copy_migrations.rake'
      load 'os_tools/railties/schema.rake'
    end 

  end 
end
