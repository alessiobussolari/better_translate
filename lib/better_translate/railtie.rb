# frozen_string_literal: true

module BetterTranslate
  # Rails integration
  #
  # Automatically loads Rake tasks when used in a Rails application.
  #
  # @example In a Rails app, tasks are available automatically:
  #   rake better_translate:translate
  #   rake better_translate:config:generate
  #
  class Railtie < Rails::Railtie
    rake_tasks do
      dir = __dir__
      rake_file = File.expand_path("../tasks/better_translate.rake", dir) if dir
      load rake_file if rake_file
    end
  end
end
