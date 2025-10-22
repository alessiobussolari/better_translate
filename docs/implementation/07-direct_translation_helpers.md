# 07 - Direct Translation Helpers

[← Previous: 06-Main Module Api](./06-main_module_api.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 08-Rails Integration →](./08-rails_integration.md)

---

## Direct Translation Helpers

Questa sezione implementa helper pubblici per tradurre stringhe direttamente, senza usare file YAML.

### 6.5.1 `lib/better_translate/helpers.rb`

```ruby
# frozen_string_literal: true

module BetterTranslate
  # Helper methods for direct text translation
  #
  # Provides convenient methods to translate text programmatically without YAML files.
  module Helpers
    # Translate a single text string
    #
    # @param text [String] Text to translate
    # @param from [String] Source language code (e.g., "en")
    # @param to [String, Array<String>] Target language code(s)
    # @param provider [Symbol, nil] Provider to use (:chatgpt, :gemini, :anthropic). Uses configured provider if nil.
    # @param context [String, nil] Optional translation context
    # @return [String, Hash] Translated text (String if single target, Hash if multiple targets)
    # @raise [ConfigurationError] if BetterTranslate is not configured and no provider specified
    # @raise [ValidationError] if input is invalid
    # @raise [TranslationError] if translation fails
    #
    # @example Single target language
    #   BetterTranslate.translate_text("Hello", from: "en", to: "it")
    #   #=> "Ciao"
    #
    # @example Multiple target languages
    #   BetterTranslate.translate_text("Hello", from: "en", to: ["it", "fr", "de"])
    #   #=> { "it" => "Ciao", "fr" => "Bonjour", "de" => "Hallo" }
    #
    # @example With custom provider
    #   BetterTranslate.translate_text("Hello", from: "en", to: "it", provider: :anthropic)
    #
    # @example With context
    #   BetterTranslate.translate_text(
    #     "The patient presents with symptoms",
    #     from: "en",
    #     to: "it",
    #     context: "Medical terminology"
    #   )
    #
    def self.translate_text(text, from:, to:, provider: nil, context: nil)
      Validator.validate_text!(text)
      Validator.validate_language_code!(from)

      # Normalize to array
      target_langs = Array(to)
      target_langs.each { |lang| Validator.validate_language_code!(lang) }

      # Get provider
      translation_provider = get_provider(provider, context)

      # Translate
      if target_langs.size == 1
        # Single target - return string
        translate_single(text, target_langs.first, translation_provider)
      else
        # Multiple targets - return hash
        translate_multiple(text, target_langs, translation_provider)
      end
    end

    # Translate multiple texts to a single target language
    #
    # @param texts [Array<String>] Texts to translate
    # @param from [String] Source language code
    # @param to [String] Target language code
    # @param provider [Symbol, nil] Provider to use
    # @param context [String, nil] Optional translation context
    # @return [Array<String>] Translated texts
    # @raise [ValidationError] if input is invalid
    # @raise [TranslationError] if translation fails
    #
    # @example
    #   BetterTranslate.translate_texts(
    #     ["Hello", "Goodbye", "Thank you"],
    #     from: "en",
    #     to: "it"
    #   )
    #   #=> ["Ciao", "Arrivederci", "Grazie"]
    #
    def self.translate_texts(texts, from:, to:, provider: nil, context: nil)
      raise ValidationError, "texts must be an Array" unless texts.is_a?(Array)
      raise ValidationError, "texts cannot be empty" if texts.empty?

      Validator.validate_language_code!(from)
      Validator.validate_language_code!(to)

      texts.each { |text| Validator.validate_text!(text) }

      # Get provider
      translation_provider = get_provider(provider, context)

      # Translate each text
      texts.map do |text|
        translate_single(text, to, translation_provider)
      end
    end

    # Translate a text to multiple languages (batch)
    #
    # @param text [String] Text to translate
    # @param from [String] Source language code
    # @param to [Array<Hash>] Target languages with format: [{ short_name: "it", name: "Italian" }]
    # @param provider [Symbol, nil] Provider to use
    # @param context [String, nil] Optional translation context
    # @return [Hash] Hash with language codes as keys and translations as values
    #
    # @example
    #   languages = [
    #     { short_name: "it", name: "Italian" },
    #     { short_name: "fr", name: "French" }
    #   ]
    #   BetterTranslate.translate_text_to_languages("Hello", from: "en", to: languages)
    #   #=> { "it" => "Ciao", "fr" => "Bonjour" }
    #
    def self.translate_text_to_languages(text, from:, to:, provider: nil, context: nil)
      raise ValidationError, "to must be an Array of Hashes" unless to.is_a?(Array)

      Validator.validate_text!(text)
      Validator.validate_language_code!(from)

      # Get provider
      translation_provider = get_provider(provider, context)

      # Translate to each language
      to.each_with_object({}) do |lang_hash, result|
        lang_code = lang_hash[:short_name]
        lang_name = lang_hash[:name] || lang_code

        Validator.validate_language_code!(lang_code)
        result[lang_code] = translation_provider.translate_text(text, lang_code, lang_name)
      end
    end

    # Translate multiple texts to multiple languages
    #
    # @param texts [Array<String>] Texts to translate
    # @param from [String] Source language code
    # @param to [Array<Hash>] Target languages
    # @param provider [Symbol, nil] Provider to use
    # @param context [String, nil] Optional translation context
    # @return [Hash] Nested hash: { "it" => ["Ciao", "Arrivederci"], "fr" => [...] }
    #
    # @example
    #   languages = [
    #     { short_name: "it", name: "Italian" },
    #     { short_name: "fr", name: "French" }
    #   ]
    #   BetterTranslate.translate_texts_to_languages(
    #     ["Hello", "Goodbye"],
    #     from: "en",
    #     to: languages
    #   )
    #   #=> { "it" => ["Ciao", "Arrivederci"], "fr" => ["Bonjour", "Au revoir"] }
    #
    def self.translate_texts_to_languages(texts, from:, to:, provider: nil, context: nil)
      raise ValidationError, "texts must be an Array" unless texts.is_a?(Array)
      raise ValidationError, "texts cannot be empty" if texts.empty?
      raise ValidationError, "to must be an Array of Hashes" unless to.is_a?(Array)

      Validator.validate_language_code!(from)
      texts.each { |text| Validator.validate_text!(text) }

      # Get provider
      translation_provider = get_provider(provider, context)

      # Translate to each language
      to.each_with_object({}) do |lang_hash, result|
        lang_code = lang_hash[:short_name]
        lang_name = lang_hash[:name] || lang_code

        Validator.validate_language_code!(lang_code)

        # Translate all texts for this language
        result[lang_code] = texts.map do |text|
          translation_provider.translate_text(text, lang_code, lang_name)
        end
      end
    end

    private_class_method def self.translate_single(text, target_lang, translation_provider)
      # Use language code as name if needed
      lang_name = target_lang.upcase

      translation_provider.translate_text(text, target_lang, lang_name)
    end

    private_class_method def self.translate_multiple(text, target_langs, translation_provider)
      target_langs.each_with_object({}) do |lang_code, result|
        result[lang_code] = translate_single(text, lang_code, translation_provider)
      end
    end

    private_class_method def self.get_provider(provider_symbol, context)
      if provider_symbol
        # Use specified provider with temporary config
        config = build_temp_config(provider_symbol, context)
        ProviderFactory.create(provider_symbol, config)
      elsif BetterTranslate.configuration
        # Use existing configuration
        config = BetterTranslate.configuration
        config.translation_context = context if context
        ProviderFactory.create(config.provider, config)
      else
        raise ConfigurationError, "BetterTranslate not configured. Either configure it or specify a provider."
      end
    end

    private_class_method def self.build_temp_config(provider_symbol, context)
      config = Configuration.new
      config.provider = provider_symbol
      config.translation_context = context if context

      # Set API keys from environment
      case provider_symbol
      when :chatgpt
        config.openai_key = ENV["OPENAI_API_KEY"]
      when :gemini
        config.google_gemini_key = ENV["GEMINI_API_KEY"]
      when :anthropic
        config.anthropic_key = ENV["ANTHROPIC_API_KEY"]
      end

      # Set minimal required fields for validation
      config.source_language = "en"
      config.target_languages = [{ short_name: "it", name: "Italian" }]
      config.input_file = "/tmp/dummy.yml"  # Not used for direct translation
      config.output_folder = "/tmp"

      config
    end
  end
end
```

### 6.5.2 Aggiornare `lib/better_translate.rb`

Aggiungere dopo la sezione dei require:

```ruby
require_relative "better_translate/helpers"
```

E aggiungere i metodi convenience al modulo principale:

```ruby
module BetterTranslate
  class << self
    # ... existing methods ...

    # Translate a text string directly
    #
    # @see Helpers.translate_text
    def translate_text(text, from:, to:, provider: nil, context: nil)
      Helpers.translate_text(text, from: from, to: to, provider: provider, context: context)
    end

    # Translate multiple texts directly
    #
    # @see Helpers.translate_texts
    def translate_texts(texts, from:, to:, provider: nil, context: nil)
      Helpers.translate_texts(texts, from: from, to: to, provider: provider, context: context)
    end

    # Translate text to multiple languages
    #
    # @see Helpers.translate_text_to_languages
    def translate_text_to_languages(text, from:, to:, provider: nil, context: nil)
      Helpers.translate_text_to_languages(text, from: from, to: to, provider: provider, context: context)
    end

    # Translate multiple texts to multiple languages
    #
    # @see Helpers.translate_texts_to_languages
    def translate_texts_to_languages(texts, from:, to:, provider: nil, context: nil)
      Helpers.translate_texts_to_languages(texts, from: from, to: to, provider: provider, context: context)
    end
  end
end
```

### 6.5.3 Test: `spec/better_translate/helpers_spec.rb`

```ruby
# frozen_string_literal: true

RSpec.describe BetterTranslate::Helpers do
  describe ".translate_text" do
    let(:config) { build_config }

    before do
      BetterTranslate.configure do |c|
        c.provider = :chatgpt
        c.openai_key = "test-key"
        c.source_language = "en"
        c.target_languages = [{ short_name: "it", name: "Italian" }]
        c.input_file = create_temp_yaml("en" => { "test" => "test" })
        c.output_folder = Dir.mktmpdir
      end
    end

    context "with single target language" do
      it "returns translated string", :vcr do
        result = described_class.translate_text("Hello", from: "en", to: "it")
        expect(result).to be_a(String)
        expect(result).to eq("Ciao")
      end
    end

    context "with multiple target languages" do
      it "returns hash of translations", :vcr do
        result = described_class.translate_text("Hello", from: "en", to: ["it", "fr"])
        expect(result).to be_a(Hash)
        expect(result.keys).to contain_exactly("it", "fr")
        expect(result["it"]).to eq("Ciao")
        expect(result["fr"]).to eq("Bonjour")
      end
    end

    context "with custom provider" do
      it "uses specified provider", :vcr do
        result = described_class.translate_text(
          "Hello",
          from: "en",
          to: "it",
          provider: :gemini
        )
        expect(result).to eq("Ciao")
      end
    end

    context "with context" do
      it "includes context in translation", :vcr do
        result = described_class.translate_text(
          "The patient presents with symptoms",
          from: "en",
          to: "it",
          context: "Medical terminology"
        )
        expect(result).to be_a(String)
      end
    end

    it "validates text input" do
      expect {
        described_class.translate_text("", from: "en", to: "it")
      }.to raise_error(BetterTranslate::ValidationError, /cannot be empty/)
    end

    it "validates language codes" do
      expect {
        described_class.translate_text("Hello", from: "invalid", to: "it")
      }.to raise_error(BetterTranslate::ValidationError, /must be 2 letters/)
    end
  end

  describe ".translate_texts" do
    before do
      BetterTranslate.configure do |c|
        c.provider = :chatgpt
        c.openai_key = "test-key"
        c.source_language = "en"
        c.target_languages = [{ short_name: "it", name: "Italian" }]
        c.input_file = create_temp_yaml("en" => { "test" => "test" })
        c.output_folder = Dir.mktmpdir
      end
    end

    it "translates array of texts", :vcr do
      result = described_class.translate_texts(
        ["Hello", "Goodbye"],
        from: "en",
        to: "it"
      )
      expect(result).to be_an(Array)
      expect(result).to eq(["Ciao", "Arrivederci"])
    end

    it "validates input is array" do
      expect {
        described_class.translate_texts("Hello", from: "en", to: "it")
      }.to raise_error(BetterTranslate::ValidationError, /must be an Array/)
    end

    it "validates array is not empty" do
      expect {
        described_class.translate_texts([], from: "en", to: "it")
      }.to raise_error(BetterTranslate::ValidationError, /cannot be empty/)
    end
  end

  describe ".translate_text_to_languages" do
    let(:languages) do
      [
        { short_name: "it", name: "Italian" },
        { short_name: "fr", name: "French" }
      ]
    end

    before do
      BetterTranslate.configure do |c|
        c.provider = :chatgpt
        c.openai_key = "test-key"
        c.source_language = "en"
        c.target_languages = languages
        c.input_file = create_temp_yaml("en" => { "test" => "test" })
        c.output_folder = Dir.mktmpdir
      end
    end

    it "translates to multiple languages", :vcr do
      result = described_class.translate_text_to_languages(
        "Hello",
        from: "en",
        to: languages
      )
      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly("it", "fr")
      expect(result["it"]).to eq("Ciao")
      expect(result["fr"]).to eq("Bonjour")
    end
  end

  describe ".translate_texts_to_languages" do
    let(:languages) do
      [
        { short_name: "it", name: "Italian" },
        { short_name: "fr", name: "French" }
      ]
    end

    before do
      BetterTranslate.configure do |c|
        c.provider = :chatgpt
        c.openai_key = "test-key"
        c.source_language = "en"
        c.target_languages = languages
        c.input_file = create_temp_yaml("en" => { "test" => "test" })
        c.output_folder = Dir.mktmpdir
      end
    end

    it "translates multiple texts to multiple languages", :vcr do
      result = described_class.translate_texts_to_languages(
        ["Hello", "Goodbye"],
        from: "en",
        to: languages
      )
      expect(result).to be_a(Hash)
      expect(result["it"]).to eq(["Ciao", "Arrivederci"])
      expect(result["fr"]).to eq(["Bonjour", "Au revoir"])
    end
  end
end

# Test module-level convenience methods
RSpec.describe BetterTranslate do
  describe ".translate_text" do
    it "delegates to Helpers.translate_text" do
      expect(BetterTranslate::Helpers).to receive(:translate_text).with(
        "Hello",
        from: "en",
        to: "it",
        provider: nil,
        context: nil
      )

      BetterTranslate.translate_text("Hello", from: "en", to: "it")
    end
  end
end
```

### 6.5.4 Example: `examples/direct_translation.rb`

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "better_translate"

# Configure BetterTranslate
BetterTranslate.configure do |config|
  config.provider = :chatgpt
  config.openai_key = ENV["OPENAI_API_KEY"]
  # Minimal configuration for direct translation
  config.source_language = "en"
  config.target_languages = [{ short_name: "it", name: "Italian" }]
  config.input_file = "/tmp/dummy.yml"
  config.output_folder = "/tmp"
end

puts "=" * 80
puts "Direct Translation Examples"
puts "=" * 80

# Example 1: Single text, single target
puts "\n1. Translate to single language:"
result = BetterTranslate.translate_text("Hello, world!", from: "en", to: "it")
puts "   EN: Hello, world!"
puts "   IT: #{result}"

# Example 2: Single text, multiple targets
puts "\n2. Translate to multiple languages:"
result = BetterTranslate.translate_text("Good morning", from: "en", to: ["it", "fr", "de"])
puts "   EN: Good morning"
result.each do |lang, translation|
  puts "   #{lang.upcase}: #{translation}"
end

# Example 3: Multiple texts, single target
puts "\n3. Translate multiple texts:"
texts = ["Hello", "Goodbye", "Thank you"]
results = BetterTranslate.translate_texts(texts, from: "en", to: "it")
texts.each_with_index do |text, i|
  puts "   #{text} => #{results[i]}"
end

# Example 4: With translation context
puts "\n4. Translation with context (medical):"
result = BetterTranslate.translate_text(
  "The patient presents with acute symptoms",
  from: "en",
  to: "it",
  context: "Medical terminology for healthcare professionals"
)
puts "   EN: The patient presents with acute symptoms"
puts "   IT: #{result}"

# Example 5: Using language hashes (like in YAML translation)
puts "\n5. Translate with full language info:"
languages = [
  { short_name: "it", name: "Italian" },
  { short_name: "fr", name: "French" },
  { short_name: "de", name: "German" }
]

result = BetterTranslate.translate_text_to_languages(
  "Welcome to our application",
  from: "en",
  to: languages
)

puts "   EN: Welcome to our application"
result.each do |lang_code, translation|
  lang_name = languages.find { |l| l[:short_name] == lang_code }[:name]
  puts "   #{lang_name} (#{lang_code}): #{translation}"
end

# Example 6: Without global configuration (using provider parameter)
puts "\n6. Direct translation without global config:"
BetterTranslate.reset!  # Clear configuration

result = BetterTranslate.translate_text(
  "Hello",
  from: "en",
  to: "it",
  provider: :anthropic  # Uses ENV['ANTHROPIC_API_KEY']
)
puts "   Using Anthropic provider directly"
puts "   Hello => #{result}"

puts "\n" + "=" * 80
```

---

---

[← Previous: 06-Main Module Api](./06-main_module_api.md) | [Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 08-Rails Integration →](./08-rails_integration.md)
