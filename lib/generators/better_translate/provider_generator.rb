require 'rails/generators'

module BetterTranslate
  module Generators
    # Generator for creating custom translation providers for BetterTranslate.
    # This generator creates a new provider class in the user's application that
    # inherits from BetterTranslate::Providers::BaseProvider.
    #
    # @example
    #   rails generate better_translate:provider DeepL
    #
    # This will create:
    #   app/providers/deep_l_provider.rb
    #
    class ProviderGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      
      # Define the destination path for the provider
      def self.destination_root
        Rails.root
      end
      
      # Creates a custom provider class in the app/providers directory
      def create_provider_file
        template 'custom_provider.rb.erb', File.join('app/providers', "#{file_name}_provider.rb")
      end
      
      # Creates the app/providers directory if it doesn't exist
      def create_providers_directory
        empty_directory 'app/providers'
      end
      
      # Adds instructions for configuring the new provider
      def show_instructions
        readme 'provider_instructions.md'
      end
      
      private
      
      # Returns the class name of the provider
      def provider_class_name
        "#{class_name}Provider"
      end
    end
  end
end
