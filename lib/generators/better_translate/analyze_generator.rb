# frozen_string_literal: true

require "rails/generators"

module BetterTranslate
  module Generators
    # Rails generator for analyzing translation files to find similar content.
    # Uses the SimilarityAnalyzer to identify potentially redundant translations
    # across locale files and generates both JSON and human-readable reports.
    #
    # @example
    #   rails generate better_translate:analyze
    class AnalyzeGenerator < Rails::Generators::Base
      desc "Analyze translation files for similarities"

      # Main generator method that analyzes translation files for similarities.
      # Finds all YAML files in the config/locales directory, runs the analysis,
      # and displays a summary of the results.
      #
      # The analysis uses the Levenshtein distance algorithm to identify strings
      # that are similar but not identical, which could indicate redundant translations.
      #
      # @return [void]
      def analyze_translations
        say "Starting translation similarity analysis...", :blue

        # Find all YAML files in the locales directory
        locale_dir = Rails.root.join("config", "locales")
        yaml_files = Dir[locale_dir.join("*.yml")]

        if yaml_files.empty?
          say "No YAML files found in #{locale_dir}", :red
          return
        end

        say "Found #{yaml_files.length} YAML files to analyze", :green

        # Run analysis
        analyzer = BetterTranslate::SimilarityAnalyzer.new(yaml_files)
        analyzer.analyze

        # Show results
        say "\nAnalysis complete!", :green
        say "Reports generated:", :green
        say "  * #{BetterTranslate::SimilarityAnalyzer::REPORT_FILE} (detailed JSON report)"
        say "  * translation_similarities_summary.txt (human-readable summary)"
        
        # Show quick summary from the text file
        if File.exist?("translation_similarities_summary.txt")
          summary = File.read("translation_similarities_summary.txt")
          say "\nQuick Summary:", :blue
          say summary
        end
      end
    end
  end
end
