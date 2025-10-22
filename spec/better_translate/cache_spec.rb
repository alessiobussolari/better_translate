# frozen_string_literal: true

RSpec.describe BetterTranslate::Cache do
  subject(:cache) { described_class.new(capacity: 3) }

  describe "#initialize" do
    it "sets capacity" do
      expect(cache.capacity).to eq(3)
    end

    it "sets default capacity to 1000" do
      default_cache = described_class.new
      expect(default_cache.capacity).to eq(1000)
    end

    it "accepts optional ttl" do
      cache_with_ttl = described_class.new(ttl: 60)
      expect(cache_with_ttl.ttl).to eq(60)
    end

    it "has nil ttl by default" do
      expect(cache.ttl).to be_nil
    end
  end

  describe "#set and #get" do
    it "stores and retrieves values" do
      cache.set("key1", "value1")
      expect(cache.get("key1")).to eq("value1")
    end

    it "returns nil for non-existent keys" do
      expect(cache.get("nonexistent")).to be_nil
    end

    it "updates existing values" do
      cache.set("key1", "value1")
      cache.set("key1", "value2")
      expect(cache.get("key1")).to eq("value2")
    end
  end

  describe "LRU behavior" do
    it "removes oldest entry when at capacity" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")
      cache.set("key4", "value4") # This should evict key1

      expect(cache.get("key1")).to be_nil
      expect(cache.get("key2")).to eq("value2")
      expect(cache.get("key3")).to eq("value3")
      expect(cache.get("key4")).to eq("value4")
    end

    it "moves accessed items to end (most recently used)" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")
      cache.set("key3", "value3")

      cache.get("key1") # Access key1, moves it to end

      cache.set("key4", "value4") # This should evict key2 (not key1)

      expect(cache.get("key1")).to eq("value1")
      expect(cache.get("key2")).to be_nil
      expect(cache.get("key3")).to eq("value3")
      expect(cache.get("key4")).to eq("value4")
    end
  end

  describe "TTL expiration" do
    let(:cache_with_ttl) { described_class.new(capacity: 10, ttl: 1) }

    it "returns nil for expired entries" do
      cache_with_ttl.set("key1", "value1")
      expect(cache_with_ttl.get("key1")).to eq("value1")

      sleep(1.1) # Wait for TTL to expire

      expect(cache_with_ttl.get("key1")).to be_nil
    end

    it "removes expired entry from cache" do
      cache_with_ttl.set("key1", "value1")
      sleep(1.1)
      cache_with_ttl.get("key1") # Triggers cleanup

      expect(cache_with_ttl.size).to eq(0)
    end
  end

  describe "#clear" do
    it "removes all entries" do
      cache.set("key1", "value1")
      cache.set("key2", "value2")

      cache.clear

      expect(cache.size).to eq(0)
      expect(cache.get("key1")).to be_nil
      expect(cache.get("key2")).to be_nil
    end
  end

  describe "#size" do
    it "returns number of entries in cache" do
      expect(cache.size).to eq(0)

      cache.set("key1", "value1")
      expect(cache.size).to eq(1)

      cache.set("key2", "value2")
      expect(cache.size).to eq(2)
    end
  end

  describe "#key?" do
    it "returns true for existing keys" do
      cache.set("key1", "value1")
      expect(cache.key?("key1")).to be true
    end

    it "returns false for non-existent keys" do
      expect(cache.key?("nonexistent")).to be false
    end

    it "returns false for expired keys" do
      cache_with_ttl = described_class.new(ttl: 1)
      cache_with_ttl.set("key1", "value1")

      sleep(1.1)

      expect(cache_with_ttl.key?("key1")).to be false
    end
  end

  describe "thread safety" do
    it "is thread-safe for concurrent operations" do
      threads = []
      100.times do |i|
        threads << Thread.new do
          cache.set("key#{i}", "value#{i}")
          cache.get("key#{i}")
        end
      end
      threads.each(&:join)

      # If thread-safe, size should be capped at capacity (3)
      expect(cache.size).to be <= 3
    end
  end
end
