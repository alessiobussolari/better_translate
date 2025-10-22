# frozen_string_literal: true

require "yaml"
require "fileutils"

module BetterTranslate
  # Handles YAML file operations
  #
  # Provides methods for:
  # - Reading and parsing YAML files
  # - Writing YAML files with proper formatting
  # - Merging translations (incremental mode)
  # - Handling exclusions
  # - Flattening/unflattening nested structures
  #
  # @example Reading a YAML file
  #   handler = YAMLHandler.new(config)
  #   data = handler.read_yaml("config/locales/en.yml")
  #
  # @example Writing translations
  #   handler.write_yaml("config/locales/it.yml", { "it" => { "greeting" => "Ciao" } })
  #
  class YAMLHandler
    # @return [Configuration] Configuration object
    attr_reader :config

    # Initialize YAML handler
    #
    # @param config [Configuration] Configuration object
    #
    # @example
    #   config = Configuration.new
    #   handler = YAMLHandler.new(config)
    #
    def initialize(config)
      @config = config
    end

    # Read and parse YAML file
    #
    # @param file_path [String] Path to YAML file
    # @return [Hash] Parsed YAML content
    # @raise [FileError] if file cannot be read
    # @raise [YamlError] if YAML is invalid
    #
    # @example
    #   data = handler.read_yaml("config/locales/en.yml")
    #   #=> { "en" => { "greeting" => "Hello" } }
    #
    def read_yaml(file_path)
      Validator.validate_file_exists!(file_path)

      content = File.read(file_path)
      YAML.safe_load(content) || {}
    rescue Errno::ENOENT => e
      raise FileError.new("File not found: #{file_path}", context: { error: e.message })
    rescue Psych::SyntaxError => e
      raise YamlError.new("Invalid YAML syntax in #{file_path}", context: { error: e.message })
    end

    # Write hash to YAML file
    #
    # @param file_path [String] Output file path
    # @param data [Hash] Data to write
    # @param diff_preview [DiffPreview, nil] Optional diff preview instance
    # @return [Hash, nil] Summary hash if dry_run, nil otherwise
    # @raise [FileError] if file cannot be written
    #
    # @example
    #   handler.write_yaml("config/locales/it.yml", { "it" => { "greeting" => "Ciao" } })
    #
    def write_yaml(file_path, data, diff_preview: nil)
      summary = nil

      # Show diff preview if in dry run mode
      if config.dry_run && diff_preview
        # @type var existing_data: Hash[String, untyped]
        existing_data = File.exist?(file_path) ? read_yaml(file_path) : {}
        summary = diff_preview.show_diff(existing_data, data, file_path)
      end

      return summary if config.dry_run

      # Ensure output directory exists
      FileUtils.mkdir_p(File.dirname(file_path))

      File.write(file_path, YAML.dump(data))

      nil
    rescue Errno::EACCES => e
      raise FileError.new("Permission denied: #{file_path}", context: { error: e.message })
    rescue StandardError => e
      raise FileError.new("Failed to write YAML: #{file_path}", context: { error: e.message })
    end

    # Get translatable strings from source YAML
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

      source_data = read_yaml(config.input_file)
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
    #   merged = handler.merge_translations("config/locales/it.yml", new_translations)
    #
    def merge_translations(file_path, new_translations)
      # @type var existing: Hash[String, untyped]
      existing = File.exist?(file_path) ? read_yaml(file_path) : {}
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
    #   #=> "config/locales/it.yml"
    #
    def build_output_path(target_lang_code)
      return "#{target_lang_code}.yml" unless config.output_folder

      File.join(config.output_folder, "#{target_lang_code}.yml")
    end
  end
end
