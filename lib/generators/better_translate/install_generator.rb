require 'rails/generators'

module BetterTranslate
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      desc "Genera il file config/initializers/better_translate.rb con la configurazione di default"

      def copy_initializer
        template "better_translate.rb", "config/initializers/better_translate.rb"
      end
    end
  end
end
