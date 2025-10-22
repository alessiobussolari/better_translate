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

    it "accepts 201 status" do
      allow(response).to receive(:status).and_return(201)
      expect { provider.send(:handle_response, response) }.not_to raise_error
    end

    it "accepts 299 status" do
      allow(response).to receive(:status).and_return(299)
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

    it "raises ApiError for 401 (unauthorized)" do
      allow(response).to receive(:status).and_return(401)
      allow(response).to receive(:body).and_return("unauthorized")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Client error: 401/)
    end

    it "raises ApiError for 404" do
      allow(response).to receive(:status).and_return(404)
      allow(response).to receive(:body).and_return("not found")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Client error: 404/)
    end

    it "raises ApiError for 500" do
      allow(response).to receive(:status).and_return(500)
      allow(response).to receive(:body).and_return("server error")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Server error: 500/)
    end

    it "raises ApiError for 503" do
      allow(response).to receive(:status).and_return(503)
      allow(response).to receive(:body).and_return("service unavailable")

      expect do
        provider.send(:handle_response, response)
      end.to raise_error(BetterTranslate::ApiError, /Server error: 503/)
    end

    it "includes context in RateLimitError" do
      allow(response).to receive(:status).and_return(429)
      allow(response).to receive(:body).and_return("rate limit details")

      begin
        provider.send(:handle_response, response)
      rescue BetterTranslate::RateLimitError => e
        expect(e.context[:status]).to eq(429)
        expect(e.context[:body]).to eq("rate limit details")
      end
    end

    it "includes context in ApiError" do
      allow(response).to receive(:status).and_return(500)
      allow(response).to receive(:body).and_return("error details")

      begin
        provider.send(:handle_response, response)
      rescue BetterTranslate::ApiError => e
        expect(e.context[:status]).to eq(500)
        expect(e.context[:body]).to eq("error details")
      end
    end
  end

  describe "#http_client" do
    it "returns a Faraday connection" do
      client = provider.send(:http_client)
      expect(client).to be_a(Faraday::Connection)
    end

    it "sets request timeout from config" do
      client = provider.send(:http_client)
      expect(client.options.timeout).to eq(30)
    end

    it "sets open timeout to 10 seconds" do
      client = provider.send(:http_client)
      expect(client.options.open_timeout).to eq(10)
    end

    it "reuses same client instance (memoization)" do
      client1 = provider.send(:http_client)
      client2 = provider.send(:http_client)
      expect(client1).to be(client2)
    end
  end

  describe "retry logic integration" do
    let(:http_client) { double("http_client") }
    let(:request) { double("request", headers: {}, body: nil) }

    before do
      allow(provider).to receive(:http_client).and_return(http_client)
      allow(provider).to receive(:sleep) # Don't actually sleep in tests
      allow(request.headers).to receive(:merge!)
      allow(request).to receive(:body=)
    end

    it "retries on RateLimitError and eventually succeeds" do
      success_response = double("response", status: 200, body: "OK")
      rate_limit_response = double("response", status: 429, body: "Rate limit")

      call_count = 0
      allow(http_client).to receive(:post) do |_url, &block|
        call_count += 1
        block&.call(request)
        call_count < 3 ? rate_limit_response : success_response
      end

      result = provider.send(:make_request, :post, "https://api.test.com")
      expect(result.status).to eq(200)
      expect(call_count).to eq(3)
    end

    it "raises error after max_retries exceeded" do
      rate_limit_response = double("response", status: 429, body: "Rate limit")

      allow(http_client).to receive(:post) do |_url, &block|
        block&.call(request)
        rate_limit_response
      end

      expect do
        provider.send(:make_request, :post, "https://api.test.com")
      end.to raise_error(BetterTranslate::RateLimitError)
    end

    it "uses exponential backoff between retries" do
      config.retry_delay = 2.0

      success_response = double("response", status: 200, body: "OK")
      rate_limit_response = double("response", status: 429, body: "Rate limit")

      call_count = 0
      http_client_local = double("http_client")
      allow(provider).to receive(:http_client).and_return(http_client_local)
      allow(http_client_local).to receive(:post) do |_url, &block|
        call_count += 1
        block&.call(request)
        call_count < 3 ? rate_limit_response : success_response
      end

      sleep_delays = []
      allow(provider).to receive(:sleep) { |delay| sleep_delays << delay }

      provider.send(:make_request, :post, "https://api.test.com")

      # Should have 2 retries, so 2 sleeps
      expect(sleep_delays.size).to eq(2)

      # First retry should be between 2s and 2.6s (2 * 1 * (1 + 0..0.3 jitter))
      expect(sleep_delays[0]).to be_between(2.0, 2.6)

      # Second retry should be between 4s and 5.2s (2 * 2 * (1 + 0..0.3 jitter))
      expect(sleep_delays[1]).to be_between(4.0, 5.2)

      # Second delay should be roughly double the first (exponential)
      ratio = sleep_delays[1] / sleep_delays[0]
      expect(ratio).to be_between(1.8, 2.2) # Allow some variance due to jitter
    end

    it "retries on ApiError (500) and eventually succeeds" do
      success_response = double("response", status: 200, body: "OK")
      server_error_response = double("response", status: 500, body: "Server error")

      call_count = 0
      allow(http_client).to receive(:post) do |_url, &block|
        call_count += 1
        block&.call(request)
        call_count < 2 ? server_error_response : success_response
      end

      result = provider.send(:make_request, :post, "https://api.test.com")
      expect(result.status).to eq(200)
      expect(call_count).to eq(2)
    end
  end
end
