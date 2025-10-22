# frozen_string_literal: true

module BetterTranslate
  # LRU (Least Recently Used) Cache implementation
  #
  # Thread-safe cache with configurable capacity and optional TTL.
  #
  # @example Basic usage
  #   cache = Cache.new(capacity: 100)
  #   cache.set("hello:it", "ciao")
  #   cache.get("hello:it") #=> "ciao"
  #
  # @example With TTL
  #   cache = Cache.new(capacity: 100, ttl: 3600)
  #   cache.set("key", "value")
  #   # After 3600 seconds, get("key") will return nil
  #
  class Cache
    # @return [Integer] Maximum number of items in cache
    attr_reader :capacity

    # @return [Integer, nil] Time to live in seconds
    attr_reader :ttl

    # Initialize a new cache
    #
    # @param capacity [Integer] Maximum cache size
    # @param ttl [Integer, nil] Time to live in seconds (nil = no expiration)
    #
    # @example Create cache with capacity and TTL
    #   cache = Cache.new(capacity: 500, ttl: 1800)
    #
    def initialize(capacity: 1000, ttl: nil)
      @capacity = capacity
      @ttl = ttl
      @cache = {}
      @mutex = Mutex.new
    end

    # Get a value from the cache
    #
    # @param key [String] Cache key
    # @return [String, nil] Cached value or nil if not found/expired
    #
    # @example Get cached value
    #   value = cache.get("translation:en:it:hello")
    #
    def get(key)
      @mutex.synchronize do
        return nil unless @cache.key?(key)

        entry = @cache[key]

        # Check TTL
        if @ttl && entry && Time.now - entry[:timestamp] > @ttl
          @cache.delete(key)
          return nil
        end

        # Move to end (most recently used)
        @cache.delete(key)
        @cache[key] = entry
        entry[:value]
      end
    end

    # Set a value in the cache
    #
    # @param key [String] Cache key
    # @param value [String] Value to cache
    # @return [String] The cached value
    #
    # @example Store value in cache
    #   cache.set("translation:en:it:hello", "ciao")
    #
    def set(key, value)
      @mutex.synchronize do
        # Remove oldest entry if at capacity
        @cache.shift if @cache.size >= @capacity && !@cache.key?(key)

        @cache[key] = {
          value: value,
          timestamp: Time.now
        }
        value
      end
    end

    # Clear the cache
    #
    # @return [void]
    #
    # @example Clear all cached values
    #   cache.clear
    #
    def clear
      @mutex.synchronize { @cache.clear }
    end

    # Get cache size
    #
    # @return [Integer] Number of items in cache
    #
    # @example Check cache size
    #   puts "Cache contains #{cache.size} items"
    #
    def size
      @mutex.synchronize { @cache.size }
    end

    # Check if key exists in cache
    #
    # @param key [String] Cache key
    # @return [Boolean] true if key exists and not expired
    #
    # @example Check if key exists
    #   if cache.key?("translation:en:it:hello")
    #     puts "Translation is cached"
    #   end
    #
    def key?(key)
      !get(key).nil?
    end
  end
end
