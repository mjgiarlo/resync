require "rails"

module Resync
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/resync.rake"
    end
  end
end
