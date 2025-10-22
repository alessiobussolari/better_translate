# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Rails generator for installing BetterTranslate
    #
    # Creates initializer and config files for Rails applications.
    #
    # @example Run generator
    #   rails generate better_translate:install
    #
    class InstallGenerator < Rails::Generators::Base
      dir = __dir__
      source_root File.expand_path("templates", dir) if dir

      desc "Creates BetterTranslate initializer and config files"

      # Create initializer file
      #
      # @return [void]
      #
      def create_initializer_file
        template "initializer.rb.tt", "config/initializers/better_translate.rb"
      end

      # Create YAML config file
      #
      # @return [void]
      #
      def create_config_file
        sample_config = {
          "provider" => "chatgpt",
          "openai_key" => "YOUR_OPENAI_API_KEY",
          "gemini_key" => "YOUR_GEMINI_API_KEY",
          "anthropic_key" => "YOUR_ANTHROPIC_API_KEY",
          "source_language" => "en",
          "target_languages" => [
            { "short_name" => "it", "name" => "Italian" },
            { "short_name" => "es", "name" => "Spanish" },
            { "short_name" => "fr", "name" => "French" }
          ],
          "input_file" => "config/locales/en.yml",
          "output_folder" => "config/locales",
          "verbose" => true,
          "dry_run" => false,
          "translation_mode" => "override",
          "preserve_variables" => true,
          "global_exclusions" => [],
          "exclusions_per_language" => {},
          "model" => nil,
          "temperature" => 0.3,
          "max_tokens" => 2000,
          "timeout" => 30,
          "max_retries" => 3,
          "rate_limit" => 10
        }

        create_file "config/better_translate.yml", sample_config.to_yaml
      end

      # Show post-install message
      #
      # @return [void]
      #
      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
