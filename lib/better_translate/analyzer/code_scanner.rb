# frozen_string_literal: true

module BetterTranslate
  module Analyzer
    # Scans code files to find i18n key references
    #
    # Supports multiple patterns:
    # - t('key') / t("key")
    # - I18n.t(:key) / I18n.t('key')
    # - <%= t('key') %> in ERB
    #
    # @example Basic usage
    #   scanner = CodeScanner.new("app/")
    #   keys = scanner.scan
    #   #=> #<Set: {"users.greeting", "products.list"}>
    #
    class CodeScanner
      # I18n patterns to match
      #
      # Matches:
      # - t('users.greeting')
      # - t("users.greeting")
      # - I18n.t(:users.greeting)
      # - I18n.t('users.greeting')
      # - I18n.translate('users.greeting')
      I18N_PATTERNS = [
        /\bt\(['"]([a-z0-9_.]+)['"]/i,             # t('key') or t("key")
        /\bI18n\.t\(:([a-z0-9_.]+)/i,              # I18n.t(:key)
        /\bI18n\.t\(['"]([a-z0-9_.]+)['"]/i,       # I18n.t('key')
        /\bI18n\.translate\(['"]([a-z0-9_.]+)['"]/i # I18n.translate('key')
      ].freeze

      # File extensions to scan
      SCANNABLE_EXTENSIONS = %w[.rb .erb .html.erb .haml .slim].freeze

      # @return [String] Path to scan (file or directory)
      attr_reader :path

      # @return [Set] Found i18n keys
      attr_reader :keys

      # @return [Array<String>] List of scanned files
      attr_reader :files_scanned

      # Initialize scanner with path
      #
      # @param path [String] File or directory path to scan
      #
      def initialize(path)
        @path = path
        @keys = Set.new
        @files_scanned = []
      end

      # Scan path and extract i18n keys
      #
      # @return [Set] Set of found i18n keys
      # @raise [FileError] if path does not exist
      #
      # @example
      #   scanner = CodeScanner.new("app/")
      #   keys = scanner.scan
      #   #=> #<Set: {"users.greeting"}>
      #
      def scan
        validate_path!

        files = collect_files
        files.each do |file|
          scan_file(file)
          @files_scanned << file
        end

        @keys
      end

      # Get count of unique keys found
      #
      # @return [Integer] Number of unique keys
      #
      def key_count
        @keys.size
      end

      private

      # Validate that path exists
      #
      # @raise [FileError] if path does not exist
      #
      def validate_path!
        return if File.exist?(path)

        raise FileError.new(
          "Path does not exist: #{path}",
          context: { path: path }
        )
      end

      # Collect all scannable files from path
      #
      # @return [Array<String>] List of file paths
      #
      def collect_files
        if File.file?(path)
          return [path] if scannable_file?(path)

          return []
        end

        Dir.glob(File.join(path, "**", "*")).select do |file|
          File.file?(file) && scannable_file?(file)
        end
      end

      # Check if file should be scanned
      #
      # @param file [String] File path
      # @return [Boolean]
      #
      def scannable_file?(file)
        SCANNABLE_EXTENSIONS.any? { |ext| file.end_with?(ext) }
      end

      # Scan single file and extract keys
      #
      # @param file [String] File path
      #
      def scan_file(file)
        content = File.read(file)

        # Remove commented lines to avoid false positives
        lines = content.split("\n")
        active_lines = lines.reject { |line| line.strip.start_with?("#", "//", "<!--") }
        active_content = active_lines.join("\n")

        I18N_PATTERNS.each do |pattern|
          active_content.scan(pattern) do |match|
            key = match.is_a?(Array) ? match.first : match
            @keys.add(key) if key
          end
        end
      rescue StandardError => e
        # Skip files that can't be read
        warn "Warning: Could not scan #{file}: #{e.message}" if ENV["VERBOSE"]
      end
    end
  end
end
