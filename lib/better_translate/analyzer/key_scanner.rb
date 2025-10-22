# frozen_string_literal: true

require "yaml"

module BetterTranslate
  module Analyzer
    # Scans YAML translation files and extracts all keys in flatten format
    #
    # @example Basic usage
    #   scanner = KeyScanner.new("config/locales/en.yml")
    #   keys = scanner.scan
    #   #=> { "users.greeting" => "Hello", "users.welcome" => "Welcome %{name}" }
    #
    class KeyScanner
      # @return [String] Path to the YAML file
      attr_reader :file_path

      # @return [Hash] Flatten keys extracted from YAML
      attr_reader :keys

      # Initialize scanner with YAML file path
      #
      # @param file_path [String] Path to YAML file
      #
      def initialize(file_path)
        @file_path = file_path
        @keys = {}
      end

      # Scan YAML file and extract all flatten keys
      #
      # @return [Hash] Flatten keys with their values
      # @raise [FileError] if file does not exist
      # @raise [YamlError] if YAML is invalid
      #
      # @example
      #   scanner = KeyScanner.new("en.yml")
      #   keys = scanner.scan
      #   #=> { "users.greeting" => "Hello" }
      #
      def scan
        validate_file!

        begin
          content = YAML.load_file(file_path)

          # Skip root language key (en, it, fr, etc.) and start from its content
          if content.is_a?(Hash) && content.size == 1
            root_key = content.keys.first.to_s
            content = content[root_key] || {} if root_key.match?(/^[a-z]{2}(-[A-Z]{2})?$/)
          end

          flatten_keys(content)
        rescue Psych::SyntaxError => e
          raise YamlError.new(
            "Invalid YAML syntax in #{file_path}",
            context: { file: file_path, error: e.message }
          )
        end

        @keys
      end

      # Get total count of keys
      #
      # @return [Integer] Number of keys
      #
      def key_count
        @keys.size
      end

      private

      # Validate that file exists
      #
      # @raise [FileError] if file does not exist
      #
      def validate_file!
        return if File.exist?(file_path)

        raise FileError.new(
          "Translation file does not exist: #{file_path}",
          context: { file: file_path }
        )
      end

      # Flatten nested hash into dot-notation keys
      #
      # @param hash [Hash] Nested hash to flatten
      # @param prefix [String] Prefix for current level
      #
      # @example
      #   flatten_keys({ "users" => { "greeting" => "Hello" } })
      #   #=> { "users.greeting" => "Hello" }
      #
      def flatten_keys(hash, prefix = nil)
        hash.each do |key, value|
          current_key = prefix ? "#{prefix}.#{key}" : key.to_s

          if value.is_a?(Hash)
            flatten_keys(value, current_key)
          else
            @keys[current_key] = value
          end
        end
      end
    end
  end
end
