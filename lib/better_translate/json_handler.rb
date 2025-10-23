# frozen_string_literal: true

require "json"
require "fileutils"

module BetterTranslate
  # Handles JSON file operations
  #
  # Provides methods for:
  # - Reading and parsing JSON files
  # - Writing JSON files with proper formatting
  # - Merging translations (incremental mode)
  # - Handling exclusions
  # - Flattening/unflattening nested structures
  #
  # @example Reading a JSON file
  #   handler = JsonHandler.new(config)
  #   data = handler.read_json("config/locales/en.json")
  #
  # @example Writing translations
  #   handler.write_json("config/locales/it.json", { "it" => { "greeting" => "Ciao" } })
  #
  class JsonHandler
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize JSON handler
    #
    # @param config [Configuration] Configuration object
    #
    # @example
    #   config = Configuration.new
    #   handler = JsonHandler.new(config)
    #
    def initialize(config)
      @config = config
    end

    # Read and parse JSON file
    #
    # @param file_path [String] Path to JSON file
    # @return [Hash] Parsed JSON content
    # @raise [FileError] if file cannot be read
    # @raise [JsonError] if JSON is invalid
    #
    # @example
    #   data = handler.read_json("config/locales/en.json")
    #   #=> { "en" => { "greeting" => "Hello" } }
    #
    def read_json(file_path)
      Validator.validate_file_exists!(file_path)

      content = File.read(file_path)
      return {} if content.strip.empty?

      JSON.parse(content)
    rescue Errno::ENOENT => e
      raise FileError.new("File does not exist: #{file_path}", context: { error: e.message })
    rescue JSON::ParserError => e
      raise JsonError.new("Invalid JSON syntax in #{file_path}", context: { error: e.message })
    end

    # Write hash to JSON file
    #
    # @param file_path [String] Output file path
    # @param data [Hash] Data to write
    # @param diff_preview [DiffPreview, nil] Optional diff preview instance
    # @return [Hash, nil] Summary hash if dry_run, nil otherwise
    # @raise [FileError] if file cannot be written
    #
    # @example
    #   handler.write_json("config/locales/it.json", { "it" => { "greeting" => "Ciao" } })
    #
    def write_json(file_path, data, diff_preview: nil)
      summary = nil

      # Show diff preview if in dry run mode
      if config.dry_run && diff_preview
        existing_data = File.exist?(file_path) ? read_json(file_path) : {} # : Hash[untyped, untyped]
        summary = diff_preview.show_diff(existing_data, data, file_path)
      end

      return summary if config.dry_run

      # Create backup if enabled and file exists
      create_backup_file(file_path) if config.create_backup && File.exist?(file_path)

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(file_path))

      # Write JSON with proper indentation
      File.write(file_path, JSON.pretty_generate(data))

      nil
    rescue Errno::EACCES => e
      raise FileError.new("Permission denied: #{file_path}", context: { error: e.message })
    rescue StandardError => e
      raise FileError.new("Failed to write JSON: #{file_path}", context: { error: e.message })
    end

    # Get translatable strings from source JSON
    #
    # Reads the input file and returns a flattened hash of strings.
    # Removes the root language key if present.
    #
    # @return [Hash] Flattened hash of translatable strings
    #
    # @example
    #   strings = handler.get_source_strings
    #   #=> { "greeting" => "Hello", "nav.home" => "Home" }
    #
    def get_source_strings
      return {} unless config.input_file

      source_data = read_json(config.input_file)
      # Remove root language key if present (e.g., "en:")
      source_data = source_data[config.source_language] || source_data

      Utils::HashFlattener.flatten(source_data)
    end

    # Filter out excluded keys for a specific language
    #
    # @param strings [Hash] Flattened strings
    # @param target_lang_code [String] Target language code
    # @return [Hash] Filtered strings
    #
    # @example
    #   filtered = handler.filter_exclusions(strings, "it")
    #
    def filter_exclusions(strings, target_lang_code)
      excluded_keys = config.global_exclusions.dup
      excluded_keys += config.exclusions_per_language[target_lang_code] || []

      strings.reject { |key, _| excluded_keys.include?(key) }
    end

    # Merge translated strings with existing file (incremental mode)
    #
    # @param file_path [String] Existing file path
    # @param new_translations [Hash] New translations (flattened)
    # @return [Hash] Merged translations (nested)
    #
    # @example
    #   merged = handler.merge_translations("config/locales/it.json", new_translations)
    #
    def merge_translations(file_path, new_translations)
      if File.exist?(file_path)
        existing = read_json(file_path)
        # Extract actual translations (remove language wrapper if present)
        target_lang = config.target_languages.first[:short_name]
        existing = existing[target_lang] || existing
      else
        existing = {} # : Hash[untyped, untyped]
      end

      existing_flat = Utils::HashFlattener.flatten(existing)

      # Merge: existing takes precedence
      merged = new_translations.merge(existing_flat)

      Utils::HashFlattener.unflatten(merged)
    end

    # Build output file path for target language
    #
    # @param target_lang_code [String] Target language code
    # @return [String] Output file path
    #
    # @example
    #   path = handler.build_output_path("it")
    #   #=> "config/locales/it.json"
    #
    def build_output_path(target_lang_code)
      return "#{target_lang_code}.json" unless config.output_folder

      File.join(config.output_folder, "#{target_lang_code}.json")
    end

    private

    # Create backup file with rotation support
    #
    # @param file_path [String] Path to file to backup
    # @return [void]
    # @api private
    #
    def create_backup_file(file_path)
      return unless File.exist?(file_path)

      # Rotate existing backups if max_backups > 1
      rotate_backups(file_path) if config.max_backups > 1

      # Create primary backup
      backup_path = "#{file_path}.bak"
      FileUtils.cp(file_path, backup_path)
    end

    # Rotate backup files, keeping only max_backups
    #
    # @param file_path [String] Base file path
    # @return [void]
    # @api private
    #
    def rotate_backups(file_path)
      primary_backup = "#{file_path}.bak"
      return unless File.exist?(primary_backup)

      # Clean up ANY backups that would exceed max_backups after rotation
      10.downto(config.max_backups) do |i|
        numbered_backup = "#{file_path}.bak.#{i}"
        FileUtils.rm_f(numbered_backup) if File.exist?(numbered_backup)
      end

      # Rotate numbered backups from high to low to avoid overwrites
      (config.max_backups - 2).downto(1) do |i|
        old_path = "#{file_path}.bak.#{i}"
        new_path = "#{file_path}.bak.#{i + 1}"

        FileUtils.mv(old_path, new_path) if File.exist?(old_path)
      end

      # Move primary backup to .bak.1
      FileUtils.mv(primary_backup, "#{file_path}.bak.1")
    end
  end
end
