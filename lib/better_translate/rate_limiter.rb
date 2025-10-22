# frozen_string_literal: true

module BetterTranslate
  # Thread-safe rate limiter
  #
  # Ensures requests are spaced out by a minimum delay.
  #
  # @example Basic usage
  #   limiter = RateLimiter.new(delay: 0.5)
  #   limiter.wait  # Waits if needed
  #   # Make API request
  #   limiter.record_request
  #
  # @example In a loop
  #   limiter = RateLimiter.new(delay: 1.0)
  #   translations.each do |text|
  #     limiter.wait
  #     result = translate_api_call(text)
  #     limiter.record_request
  #   end
  #
  class RateLimiter
    # @return [Float] Delay between requests in seconds
    attr_reader :delay

    # Initialize a new rate limiter
    #
    # @param delay [Float] Delay in seconds between requests
    #
    # @example Create rate limiter with 1 second delay
    #   limiter = RateLimiter.new(delay: 1.0)
    #
    def initialize(delay: 0.5)
      @delay = delay
      @last_request_time = nil
      @mutex = Mutex.new
    end

    # Wait if necessary to respect rate limit
    #
    # Calculates time elapsed since last request and sleeps
    # for the remaining time if needed.
    #
    # @return [void]
    #
    # @example Wait before making request
    #   limiter.wait
    #   response = api_client.post(data)
    #   limiter.record_request
    #
    def wait
      @mutex.synchronize do
        return if @last_request_time.nil?

        elapsed = Time.now - @last_request_time
        sleep_time = @delay - elapsed.to_f

        sleep(sleep_time) if sleep_time.positive?
      end
    end

    # Record that a request was made
    #
    # Should be called immediately after making a request.
    #
    # @return [void]
    #
    # @example Record request timestamp
    #   response = api_client.post(data)
    #   limiter.record_request
    #
    def record_request
      @mutex.synchronize { @last_request_time = Time.now }
    end

    # Reset the rate limiter
    #
    # Clears the last request time. Useful for testing or
    # when switching contexts.
    #
    # @return [void]
    #
    # @example Reset limiter
    #   limiter.reset
    #
    def reset
      @mutex.synchronize { @last_request_time = nil }
    end
  end
end
