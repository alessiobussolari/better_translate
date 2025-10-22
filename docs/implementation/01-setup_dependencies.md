# 01 - Setup Dependencies & Infrastructure

[← Previous: 00-Overview](./00-overview.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 02-Error Handling →](./02-error_handling.md)

---

## Setup Dependencies & Infrastructure

### 1.1 Aggiornare `Gemfile`

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "rake", "~> 13.0"

# Development & Testing
gem "rspec", "~> 3.0"
gem "rubocop", "~> 1.21"
gem "webmock", "~> 3.18"
gem "vcr", "~> 6.1"
gem "yard", "~> 0.9"
gem "bundler-audit", "~> 0.9"
```

### 1.2 Aggiornare `better_translate.gemspec`

```ruby
# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name = "better_translate"
  spec.version = BetterTranslate::VERSION
  spec.authors = ["alessiobussolari"]
  spec.email = ["alessio.bussolari@pandev.it"]

  spec.summary = "AI-powered YAML locale file translator for Rails and Ruby projects"
  spec.description = "Automatically translate YAML locale files using AI providers (ChatGPT, Gemini, Claude). Features intelligent caching, batch processing, and Rails integration."
  spec.homepage = "https://github.com/alessiobussolari/better_translate"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alessiobussolari/better_translate"
  spec.metadata["changelog_uri"] = "https://github.com/alessiobussolari/better_translate/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
end
```

### 1.3 Creare `.yardopts`

```
--markup markdown
--readme README.md
--private
--protected
--output-dir doc
lib/**/*.rb
-
CHANGELOG.md
LICENSE.txt
docs/FEATURES.md
```

### 1.4 Configuration File Support (Non-Rails Projects)

For pure Ruby projects without Rails initializers, BetterTranslate can load configuration from a `.better_translate.yml` file.

**IMPORTANT**: This feature is only used when:
- No Rails initializer exists (`config/initializers/better_translate.rb`)
- Running in a pure Ruby project (not Rails)
- Configuration file is found at project root

#### 1.4.1 `lib/better_translate/config_loader.rb`

```ruby
# frozen_string_literal: true

require "yaml"

module BetterTranslate
  # Loads configuration from .better_translate.yml file
  #
  # Used for pure Ruby projects without Rails initializers.
  # Searches for .better_translate.yml in:
  # 1. Current working directory
  # 2. Project root (detected by presence of Gemfile, .git, etc.)
  #
  # @example .better_translate.yml
  #   provider: chatgpt
  #   source_language: en
  #   target_languages:
  #     - short_name: it
  #       name: Italian
  #     - short_name: fr
  #       name: French
  #   openai_key: ENV['OPENAI_API_KEY']
  #   verbose: true
  #
  class ConfigLoader
    # Default configuration file name
    CONFIG_FILE_NAME = ".better_translate.yml"

    # Project root markers
    ROOT_MARKERS = %w[Gemfile .git Rakefile].freeze

    # @return [String, nil] Path to configuration file if found
    attr_reader :config_file_path

    # Initialize config loader
    def initialize
      @config_file_path = find_config_file
    end

    # Check if configuration file exists
    #
    # @return [Boolean] true if config file found
    def config_file_exists?
      !@config_file_path.nil?
    end

    # Load configuration from file
    #
    # @return [Hash] Configuration hash
    # @raise [ConfigurationError] if file cannot be loaded
    def load
      unless config_file_exists?
        raise ConfigurationError, "Configuration file #{CONFIG_FILE_NAME} not found"
      end

      content = File.read(@config_file_path)
      config_hash = YAML.safe_load(content, permitted_classes: [Symbol])

      validate_config_hash!(config_hash)
      resolve_env_vars!(config_hash)

      config_hash
    rescue Psych::SyntaxError => e
      raise ConfigurationError.new(
        "Invalid YAML syntax in #{@config_file_path}",
        context: { error: e.message }
      )
    rescue Errno::ENOENT => e
      raise ConfigurationError.new(
        "Configuration file not found: #{@config_file_path}",
        context: { error: e.message }
      )
    end

    # Load and apply configuration to BetterTranslate
    #
    # @return [void]
    def load_and_configure!
      config_hash = load

      BetterTranslate.configure do |config|
        apply_config_hash(config, config_hash)
      end
    end

    private

    # Find configuration file in current directory or project root
    #
    # @return [String, nil] Path to config file or nil
    def find_config_file
      # Check current directory
      current_dir_config = File.join(Dir.pwd, CONFIG_FILE_NAME)
      return current_dir_config if File.exist?(current_dir_config)

      # Check project root
      project_root = find_project_root
      if project_root
        root_config = File.join(project_root, CONFIG_FILE_NAME)
        return root_config if File.exist?(root_config)
      end

      nil
    end

    # Find project root by looking for marker files
    #
    # @return [String, nil] Project root path or nil
    def find_project_root
      current = Dir.pwd

      loop do
        return current if ROOT_MARKERS.any? { |marker| File.exist?(File.join(current, marker)) }

        parent = File.dirname(current)
        break if parent == current # Reached filesystem root

        current = parent
      end

      nil
    end

    # Validate configuration hash structure
    #
    # @param config_hash [Hash] Configuration hash
    # @raise [ConfigurationError] if validation fails
    # @return [void]
    def validate_config_hash!(config_hash)
      unless config_hash.is_a?(Hash)
        raise ConfigurationError, "Configuration must be a hash"
      end

      # Check for required keys
      required_keys = %w[provider source_language target_languages]
      missing_keys = required_keys - config_hash.keys.map(&:to_s)

      if missing_keys.any?
        raise ConfigurationError,
              "Missing required configuration keys: #{missing_keys.join(', ')}"
      end

      # Validate target_languages structure
      target_langs = config_hash["target_languages"] || config_hash[:target_languages]
      unless target_langs.is_a?(Array)
        raise ConfigurationError, "target_languages must be an array"
      end

      target_langs.each do |lang|
        unless lang.is_a?(Hash) && lang.key?("short_name") && lang.key?("name")
          raise ConfigurationError,
                "Each target language must have 'short_name' and 'name' keys"
        end
      end
    end

    # Resolve ENV variable references in configuration
    #
    # Replaces strings like "ENV['OPENAI_API_KEY']" with actual ENV values
    #
    # @param config_hash [Hash] Configuration hash
    # @return [void]
    def resolve_env_vars!(config_hash)
      config_hash.each do |key, value|
        next unless value.is_a?(String)

        # Match patterns like ENV['KEY'] or ENV["KEY"]
        if value =~ /\AENV\[['"]([^'"]+)['"]\]\z/
          env_key = Regexp.last_match(1)
          config_hash[key] = ENV.fetch(env_key, nil)
        end
      end
    end

    # Apply configuration hash to Configuration object
    #
    # @param config [Configuration] Configuration object
    # @param config_hash [Hash] Configuration hash from YAML
    # @return [void]
    def apply_config_hash(config, config_hash)
      config_hash.each do |key, value|
        setter = "#{key}="

        if config.respond_to?(setter)
          # Convert string keys to symbols for provider
          value = value.to_sym if key.to_s == "provider"

          # Convert target_languages hashes to symbol keys
          if key.to_s == "target_languages"
            value = value.map { |lang| symbolize_keys(lang) }
          end

          config.public_send(setter, value)
        end
      end
    end

    # Convert hash keys to symbols
    #
    # @param hash [Hash] Hash with string keys
    # @return [Hash] Hash with symbol keys
    def symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
```

#### 1.4.2 Integration with Main Module

Update `lib/better_translate.rb` to automatically load configuration file:

```ruby
# At the end of the module, add:

# Auto-load configuration file if present (non-Rails projects)
#
# Only loads if:
# - Not in Rails environment (no Rails initializer)
# - Configuration file exists
# - No manual configuration has been set
def self.auto_load_config_file
  return if defined?(Rails) # Skip in Rails (use initializer)
  return if @config && @config.provider # Already configured

  loader = ConfigLoader.new
  return unless loader.config_file_exists?

  loader.load_and_configure!
  puts "[BetterTranslate] Loaded configuration from #{loader.config_file_path}" if @config.verbose
rescue ConfigurationError => e
  warn "[BetterTranslate] Failed to load configuration file: #{e.message}"
end

# Auto-load on require (for non-Rails projects)
auto_load_config_file unless defined?(Rails)
```

#### 1.4.3 Example Configuration File: `.better_translate.yml`

```yaml
# BetterTranslate Configuration
# For pure Ruby projects without Rails

# Provider selection
# Options: chatgpt, gemini, anthropic
provider: chatgpt

# Source language
source_language: en

# Target languages
target_languages:
  - short_name: it
    name: Italian
  - short_name: fr
    name: French
  - short_name: de
    name: German
  - short_name: es
    name: Spanish

# API Keys (use ENV variables for security)
openai_key: ENV['OPENAI_API_KEY']
google_gemini_key: ENV['GOOGLE_GEMINI_API_KEY']
anthropic_key: ENV['ANTHROPIC_API_KEY']

# Translation settings
translation_mode: incremental  # or: override
batch_size: 10
verbose: true
preserve_variables: true
dry_run: false

# File paths
input_file: config/locales/en.yml
output_folder: config/locales

# Cache settings
cache_enabled: true
cache_ttl: 86400  # 24 hours
cache_capacity: 1000

# Rate limiting
rate_limit: 10
rate_limit_period: 60

# HTTP settings
http_timeout: 30
max_retries: 3

# Exclusions
global_exclusions:
  - debug.test_key
  - internal.private_data

# Per-language exclusions
exclusions_per_language:
  it:
    - specific.italian_key
  fr:
    - specific.french_key

# Context for better translations
context: "This is a web application for e-commerce"
```

#### 1.4.4 Test: `spec/better_translate/config_loader_spec.rb`

```ruby
# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::ConfigLoader do
  let(:config_content) do
    <<~YAML
      provider: chatgpt
      source_language: en
      target_languages:
        - short_name: it
          name: Italian
        - short_name: fr
          name: French
      openai_key: ENV['OPENAI_API_KEY']
      verbose: true
    YAML
  end

  describe "#config_file_exists?" do
    it "returns false when no config file exists" do
      loader = described_class.new
      allow(loader).to receive(:find_config_file).and_return(nil)

      expect(loader.config_file_exists?).to be false
    end

    it "returns true when config file exists" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, config_content)

        allow(Dir).to receive(:pwd).and_return(dir)

        loader = described_class.new
        expect(loader.config_file_exists?).to be true
      end
    end
  end

  describe "#load" do
    it "loads valid configuration file" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, config_content)

        allow(Dir).to receive(:pwd).and_return(dir)
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return("test_key")

        loader = described_class.new
        config = loader.load

        expect(config["provider"]).to eq("chatgpt")
        expect(config["source_language"]).to eq("en")
        expect(config["target_languages"].size).to eq(2)
        expect(config["openai_key"]).to eq("test_key")
      end
    end

    it "raises error for missing required keys" do
      invalid_config = "provider: chatgpt\n"

      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, invalid_config)

        allow(Dir).to receive(:pwd).and_return(dir)

        loader = described_class.new

        expect {
          loader.load
        }.to raise_error(BetterTranslate::ConfigurationError, /Missing required/)
      end
    end

    it "resolves ENV variable references" do
      config_with_env = <<~YAML
        provider: gemini
        source_language: en
        target_languages:
          - short_name: it
            name: Italian
        google_gemini_key: ENV['GEMINI_KEY']
      YAML

      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, config_with_env)

        allow(Dir).to receive(:pwd).and_return(dir)
        allow(ENV).to receive(:fetch).with("GEMINI_KEY", nil).and_return("my_gemini_key")

        loader = described_class.new
        config = loader.load

        expect(config["google_gemini_key"]).to eq("my_gemini_key")
      end
    end

    it "raises error for invalid YAML syntax" do
      invalid_yaml = "provider: chatgpt\n  invalid: : yaml"

      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, invalid_yaml)

        allow(Dir).to receive(:pwd).and_return(dir)

        loader = described_class.new

        expect {
          loader.load
        }.to raise_error(BetterTranslate::ConfigurationError, /Invalid YAML syntax/)
      end
    end
  end

  describe "#find_project_root" do
    it "finds project root by Gemfile" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "Gemfile"), "")

        allow(Dir).to receive(:pwd).and_return(File.join(dir, "nested", "deep"))

        loader = described_class.new
        root = loader.send(:find_project_root)

        expect(root).to eq(dir)
      end
    end

    it "returns nil if no root markers found" do
      loader = described_class.new

      allow(Dir).to receive(:pwd).and_return("/")

      root = loader.send(:find_project_root)
      expect(root).to be_nil
    end
  end

  describe "#load_and_configure!" do
    it "applies configuration to BetterTranslate module" do
      Dir.mktmpdir do |dir|
        config_path = File.join(dir, ".better_translate.yml")
        File.write(config_path, config_content)

        allow(Dir).to receive(:pwd).and_return(dir)
        allow(ENV).to receive(:fetch).with("OPENAI_API_KEY", nil).and_return("test_key")

        BetterTranslate.reset!

        loader = described_class.new
        loader.load_and_configure!

        config = BetterTranslate.config

        expect(config.provider).to eq(:chatgpt)
        expect(config.source_language).to eq("en")
        expect(config.verbose).to be true
        expect(config.openai_key).to eq("test_key")
      end
    end
  end
end
```

---

## Usage Examples

### Example 1: Pure Ruby Project with Config File

```bash
# Project structure
my_ruby_app/
├── .better_translate.yml  # Configuration file
├── Gemfile
├── config/
│   └── locales/
│       └── en.yml
└── translate.rb

# translate.rb
require "better_translate"

# Configuration is automatically loaded from .better_translate.yml
BetterTranslate.translate_all

puts "Translation complete!"
```

### Example 2: Explicit Config File Loading

```ruby
require "better_translate"

# Manually load configuration file
loader = BetterTranslate::ConfigLoader.new

if loader.config_file_exists?
  loader.load_and_configure!
  BetterTranslate.translate_all
else
  puts "No configuration file found. Please create .better_translate.yml"
end
```

### Example 3: Override Config File Settings

```ruby
require "better_translate"

# Auto-load from file, then override specific settings
BetterTranslate.configure do |config|
  config.verbose = true
  config.dry_run = true  # Override to preview changes
end

BetterTranslate.translate_all
```

---

## CLI Integration

The standalone CLI (Phase 12) will automatically detect and use `.better_translate.yml`:

```bash
# CLI automatically loads .better_translate.yml if present
better_translate translate config/locales/en.yml

# Or specify custom config file
better_translate translate config/locales/en.yml --config my_config.yml
```

---

## Benefits

1. **Zero Configuration**: Pure Ruby projects work with just a YAML file
2. **Security**: API keys stored in ENV variables
3. **Version Control**: Configuration can be committed (without secrets)
4. **Portability**: Same config file works across team members
5. **Rails Compatible**: Auto-disabled in Rails (use initializer instead)

---

## Implementation Checklist

- [ ] Create `lib/better_translate/config_loader.rb`
- [ ] Update `lib/better_translate.rb` to auto-load config file
- [ ] Create comprehensive test suite in `spec/better_translate/config_loader_spec.rb`
- [ ] Add example `.better_translate.yml` to repository
- [ ] Update CLI to support `--config` flag (Phase 12)
- [ ] Add YARD documentation for all methods
- [ ] Update README with configuration file examples
- [ ] Add `.better_translate.yml` to `.gitignore` template (optional)

---

---

[← Previous: 00-Overview](./00-overview.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 02-Error Handling →](./02-error_handling.md)
