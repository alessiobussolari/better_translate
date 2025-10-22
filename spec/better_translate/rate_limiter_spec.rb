# frozen_string_literal: true

RSpec.describe BetterTranslate::RateLimiter do
  subject(:limiter) { described_class.new(delay: 0.1) }

  describe "#initialize" do
    it "sets delay" do
      expect(limiter.delay).to eq(0.1)
    end

    it "sets default delay to 0.5" do
      default_limiter = described_class.new
      expect(default_limiter.delay).to eq(0.5)
    end
  end

  describe "#wait and #record_request" do
    it "does not wait on first request" do
      start_time = Time.now
      limiter.wait
      limiter.record_request
      elapsed = Time.now - start_time

      expect(elapsed).to be < 0.05 # Should be nearly instant
    end

    it "waits for delay between requests" do
      limiter.record_request
      sleep(0.05) # Wait less than delay

      start_time = Time.now
      limiter.wait
      elapsed = Time.now - start_time

      # Should wait approximately (0.1 - 0.05) = 0.05 seconds
      expect(elapsed).to be >= 0.04
      expect(elapsed).to be < 0.08
    end

    it "does not wait if enough time has passed" do
      limiter.record_request
      sleep(0.15) # Wait more than delay

      start_time = Time.now
      limiter.wait
      elapsed = Time.now - start_time

      # Should not wait at all
      expect(elapsed).to be < 0.05
    end
  end

  describe "#reset" do
    it "resets the last request time" do
      limiter.record_request
      limiter.reset

      start_time = Time.now
      limiter.wait
      elapsed = Time.now - start_time

      # After reset, should not wait
      expect(elapsed).to be < 0.05
    end
  end

  describe "thread safety" do
    it "is thread-safe for concurrent operations" do
      threads = []
      10.times do
        threads << Thread.new do
          limiter.wait
          limiter.record_request
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end
