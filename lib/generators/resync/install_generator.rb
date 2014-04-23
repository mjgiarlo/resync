module Resync
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def generate_config
        copy_file "resync.rb", "config/resync.rb"
      end
    end
  end
end
