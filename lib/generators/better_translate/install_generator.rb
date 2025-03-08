require 'rails/generators'

module BetterTranslate
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Crea il file di configurazione in config/initializers/better_translate.rb"

      def copy_initializer
        template "better_translate_initializer.rb", "config/initializers/better_translate.rb"
      end
    end
  end
end
