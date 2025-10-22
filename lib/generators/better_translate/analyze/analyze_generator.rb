# frozen_string_literal: true

require "rails/generators/base"

module BetterTranslate
  module Generators
    # Rails generator for analyzing YAML locale files
    #
    # Provides statistics about translation files: string count, structure, etc.
    #
    # @example Analyze a file
    #   rails generate better_translate:analyze config/locales/en.yml
    #
    class AnalyzeGenerator < Rails::Generators::Base
      dir = __dir__
      source_root File.expand_path("templates", dir) if dir

      desc "Analyze YAML locale file structure and statistics"

      argument :file_path,
               type: :string,
               required: false,
               default: "config/locales/en.yml",
               desc: "Path to YAML file to analyze"

      # Analyze YAML file
      #
      # @return [void]
      #
      def analyze_file
        full_path = Rails.root.join(file_path)

        unless File.exist?(full_path)
          say "File not found: #{full_path}", :red
          return
        end

        say "Analyzing: #{file_path}", :green
        say "=" * 60

        begin
          data = YAML.load_file(full_path)

          # Flatten to count strings
          flattened = BetterTranslate::Utils::HashFlattener.flatten(data)

          say ""
          say "Total strings: #{flattened.size}", :cyan
          say ""

          # Show structure
          say "Structure:", :yellow
          show_structure(data, 0)

          say ""
          say "=" * 60
          say "Analysis complete", :green
        rescue StandardError => e
          say "Error analyzing file: #{e.message}", :red
        end
      end

      private

      # Show nested structure
      #
      # @param hash [Hash] Hash to show
      # @param level [Integer] Nesting level
      # @return [void]
      # @api private
      #
      def show_structure(hash, level)
        hash.each do |key, value|
          indent = "  " * level
          if value.is_a?(Hash)
            say "#{indent}#{key}/ (#{count_strings(value)} strings)", :white
            show_structure(value, level + 1)
          else
            say "#{indent}#{key}: #{value.to_s[0..50]}#{value.to_s.length > 50 ? "..." : ""}", :white
          end
        end
      end

      # Count strings in nested hash
      #
      # @param hash [Hash] Hash to count
      # @return [Integer] String count
      # @api private
      #
      def count_strings(hash)
        BetterTranslate::Utils::HashFlattener.flatten(hash).size
      end
    end
  end
end
