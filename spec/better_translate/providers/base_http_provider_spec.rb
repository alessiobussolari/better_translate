# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Providers::BaseHttpProvider do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config.max_retries = 3
    config.retry_delay = 0.1
    config.request_timeout = 30
    config.cache_enabled = true
    config.cache_size = 100
    config.cache_ttl = nil
    config.verbose = false
    config
  end

  subject(:provider) { described_class.new(config) }

  describe "#initialize" do
    it "sets config" do
      expect(provider.config).to eq(config)
    end

    it "creates cache instance" do
      expect(provider.cache).to be_a(BetterTranslate::Cache)
    end

    it "creates rate limiter instance" do
      expect(provider.rate_limiter).to be_a(BetterTranslate::RateLimiter)
    end
  end

  describe "#translate_text" do
    it "raises NotImplementedError" do
      expect do
        provider.translate_text("Hello", "it", "Italian")
      end.to raise_error(NotImplementedError, /must implement #translate_text/)
    end
  end

  describe "#translate_batch" do
    it "raises NotImplementedError" do
      expect do
        provider.translate_batch(["Hello"], "it", "Italian")
      end.to raise_error(NotImplementedError, /must implement #translate_batch/)
    end
  end

  describe "#calculate_backoff" do
    it "calculates exponential backoff for attempt 1" do
      backoff = provider.send(:calculate_backoff, 1)
      expect(backoff).to be_between(0.1, 0.2)
    end

    it "calculates exponential backoff for attempt 2" do
      backoff = provider.send(:calculate_backoff, 2)
      expect(backoff).to be_between(0.2, 0.4)
    end

    it "caps at max delay" do
      backoff = provider.send(:calculate_backoff, 20)
      expect(backoff).to be <= 60.0
    end
  end

  describe "#build_cache_key" do
    it "builds cache key from text and language" do
      key = provider.send(:build_cache_key, "Hello", "it")
      expect(key).to eq("Hello:it")
    end
  end

  describe "#with_cache" do
    it "yields if caching is disabled" do
      config.cache_enabled = false
      result = provider.send(:with_cache, "test_key") { "computed" }
      expect(result).to eq("computed")
    end

    it "returns cached value if available" do
      provider.cache.set("test_key", "cached")
      result = provider.send(:with_cache, "test_key") { "computed" }
      expect(result).to eq("cached")
    end

    it "computes and caches if not available" do
      result = provider.send(:with_cache, "test_key") { "computed" }
      expect(result).to eq("computed")
      expect(provider.cache.get("test_key")).to eq("computed")
    end
  end

  describe "#handle_response" do
    let(:response) { double("response") }

    it "accepts 200 status" do
      allow(response).to receive(:status).and_return(200)
      expect { provider.send(:handle_response, response) }.not_to raise_error
    end

    it "raises RateLimitError for 429" do
      allow(response).to receive(:status).and_return(429)
      allow(response).to receive(:body).and_return("rate limited")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::RateLimitError, /Rate limit exceeded/)
    end

    it "raises ApiError for 400" do
      allow(response).to receive(:status).and_return(400)
      allow(response).to receive(:body).and_return("bad request")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Client error: 400/)
    end

    it "raises ApiError for 500" do
      allow(response).to receive(:status).and_return(500)
      allow(response).to receive(:body).and_return("server error")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Server error: 500/)
    end
  end
end
