# 09 - Testing Suite

[← Previous: 08-Rails Integration](./08-rails_integration.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 10-Documentation Examples →](./10-documentation_examples.md)

---

## Testing Suite

### 8.1 Aggiornare `spec/spec_helper.rb`

```ruby
# frozen_string_literal: true

require "better_translate"
require "webmock/rspec"
require "vcr"

# Load support files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Disable external HTTP requests
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  # Reset BetterTranslate configuration before each test
  config.before(:each) do
    BetterTranslate.reset!
  end
end
```

### 8.2 `spec/support/vcr.rb`

```ruby
# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV["OPENAI_API_KEY"] }
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV["GEMINI_API_KEY"] }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }

  # Allow real HTTP for specific tests if needed
  config.allow_http_connections_when_no_cassette = false

  # Default cassette options
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
end
```

### 8.3 `spec/support/test_helpers.rb`

```ruby
# frozen_string_literal: true

module TestHelpers
  # Create a temporary YAML file for testing
  #
  # @param content [Hash] YAML content
  # @return [String] Path to temporary file
  def create_temp_yaml(content)
    file = Tempfile.new(["test", ".yml"])
    file.write(YAML.dump(content))
    file.close
    file.path
  end

  # Create a test configuration
  #
  # @param overrides [Hash] Configuration overrides
  # @return [BetterTranslate::Configuration] Configuration object
  def build_config(**overrides)
    config = BetterTranslate::Configuration.new

    # Set defaults
    config.provider = :chatgpt
    config.openai_key = "test-api-key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = create_temp_yaml("en" => { "hello" => "Hello" })
    config.output_folder = Dir.mktmpdir

    # Apply overrides
    overrides.each do |key, value|
      config.send("#{key}=", value)
    end

    config
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
```

### 8.4 `spec/fixtures/en.yml`

```yaml
en:
  hello: "Hello"
  goodbye: "Goodbye"
  welcome:
    message: "Welcome to our application"
    subtitle: "We're glad you're here"
  user:
    profile:
      name: "Name"
      email: "Email"
      password: "Password"
  errors:
    not_found: "Resource not found"
    unauthorized: "You are not authorized"
```

### 8.5 Test Files Listing

Creare questi spec files (esempio di struttura per ognuno):

- `spec/better_translate/configuration_spec.rb` - Test validazione e configurazione
- `spec/better_translate/cache_spec.rb` - Test LRU cache
- `spec/better_translate/rate_limiter_spec.rb` - Test rate limiting
- `spec/better_translate/validator_spec.rb` - Test validazione input
- `spec/better_translate/yaml_handler_spec.rb` - Test YAML operations
- `spec/better_translate/translator_spec.rb` - Test main translator
- `spec/better_translate/progress_tracker_spec.rb` - Test progress display
- `spec/better_translate/provider_factory_spec.rb` - Test factory pattern
- `spec/better_translate/providers/chatgpt_provider_spec.rb` - Test ChatGPT provider
- `spec/better_translate/providers/gemini_provider_spec.rb` - Test Gemini provider
- `spec/better_translate/providers/anthropic_provider_spec.rb` - Test Anthropic provider
- `spec/better_translate/strategies/deep_strategy_spec.rb` - Test deep strategy
- `spec/better_translate/strategies/batch_strategy_spec.rb` - Test batch strategy
- `spec/better_translate/utils/hash_flattener_spec.rb` - Test hash utilities
- `spec/integration/translation_workflow_spec.rb` - End-to-end integration tests

### 8.6 Esempio Test: `spec/better_translate/configuration_spec.rb`

```ruby
# frozen_string_literal: true

RSpec.describe BetterTranslate::Configuration do
  describe "#initialize" do
    it "sets default values" do
      config = described_class.new

      expect(config.translation_mode).to eq(:override)
      expect(config.max_concurrent_requests).to eq(3)
      expect(config.request_timeout).to eq(30)
      expect(config.cache_enabled).to be true
      expect(config.cache_size).to eq(1000)
      expect(config.verbose).to be false
    end
  end

  describe "#validate!" do
    let(:config) { build_config }

    it "validates successfully with all required fields" do
      expect { config.validate! }.not_to raise_error
    end

    it "raises error when provider is nil" do
      config.provider = nil
      expect { config.validate! }.to raise_error(
        BetterTranslate::ConfigurationError,
        "Provider must be set"
      )
    end

    it "raises error when API key is missing for ChatGPT" do
      config.provider = :chatgpt
      config.openai_key = nil
      expect { config.validate! }.to raise_error(
        BetterTranslate::ConfigurationError,
        /OpenAI API key is required/
      )
    end

    it "raises error when source language is empty" do
      config.source_language = ""
      expect { config.validate! }.to raise_error(
        BetterTranslate::ConfigurationError,
        "Source language must be set"
      )
    end

    it "raises error when target languages is empty" do
      config.target_languages = []
      expect { config.validate! }.to raise_error(
        BetterTranslate::ConfigurationError,
        "At least one target language is required"
      )
    end

    it "raises error when input file does not exist" do
      config.input_file = "/non/existent/file.yml"
      expect { config.validate! }.to raise_error(
        BetterTranslate::ConfigurationError,
        /Input file does not exist/
      )
    end
  end
end
```

---

---

[← Previous: 08-Rails Integration](./08-rails_integration.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 10-Documentation Examples →](./10-documentation_examples.md)
