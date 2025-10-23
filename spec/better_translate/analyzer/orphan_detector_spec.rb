# frozen_string_literal: true

RSpec.describe BetterTranslate::Analyzer::OrphanDetector do
  let(:all_keys) do
    {
      "users.greeting" => "Hello",
      "users.welcome" => "Welcome %<name>s",
      "users.profile.title" => "User Profile",
      "users.profile.edit" => "Edit Profile",
      "products.list" => "Product List",
      "products.show" => "Product Details",
      "orphan_key" => "This is never used",
      "another.orphan" => "Another unused key"
    }
  end

  let(:used_keys) do
    Set.new([
              "users.greeting",
              "users.welcome",
              "users.profile.title",
              "products.list",
              "products.show",
              "users.profile.edit"
            ])
  end

  describe "#detect" do
    it "identifies keys that are not used in code" do
      detector = described_class.new(all_keys, used_keys)
      orphans = detector.detect

      expect(orphans).to be_an(Array)
      expect(orphans).to include("orphan_key")
      expect(orphans).to include("another.orphan")
    end

    it "does not include keys that are used" do
      detector = described_class.new(all_keys, used_keys)
      orphans = detector.detect

      expect(orphans).not_to include("users.greeting")
      expect(orphans).not_to include("products.list")
    end

    it "returns empty array when all keys are used" do
      all_used = Set.new(all_keys.keys)
      detector = described_class.new(all_keys, all_used)
      orphans = detector.detect

      expect(orphans).to be_empty
    end

    it "returns all keys when none are used" do
      no_used = Set.new
      detector = described_class.new(all_keys, no_used)
      orphans = detector.detect

      expect(orphans.size).to eq(all_keys.size)
    end

    it "is case sensitive" do
      keys_with_case = { "Users.Greeting" => "Hello", "users.greeting" => "Hi" }
      used = Set.new(["users.greeting"])

      detector = described_class.new(keys_with_case, used)
      orphans = detector.detect

      expect(orphans).to include("Users.Greeting")
      expect(orphans).not_to include("users.greeting")
    end
  end

  describe "#orphan_count" do
    it "returns count of orphan keys" do
      detector = described_class.new(all_keys, used_keys)
      detector.detect

      expect(detector.orphan_count).to eq(2)
    end
  end

  describe "#orphan_details" do
    it "returns hash with key and value for orphans" do
      detector = described_class.new(all_keys, used_keys)
      detector.detect

      details = detector.orphan_details

      expect(details).to be_a(Hash)
      expect(details["orphan_key"]).to eq("This is never used")
      expect(details["another.orphan"]).to eq("Another unused key")
    end

    it "does not include used keys in details" do
      detector = described_class.new(all_keys, used_keys)
      detector.detect

      details = detector.orphan_details

      expect(details).not_to have_key("users.greeting")
      expect(details).not_to have_key("products.list")
    end
  end

  describe "#usage_percentage" do
    it "calculates percentage of used keys" do
      detector = described_class.new(all_keys, used_keys)
      detector.detect

      # 6 used out of 8 total = 75%
      expect(detector.usage_percentage).to eq(75.0)
    end

    it "returns 100 when all keys are used" do
      all_used = Set.new(all_keys.keys)
      detector = described_class.new(all_keys, all_used)
      detector.detect

      expect(detector.usage_percentage).to eq(100.0)
    end

    it "returns 0 when no keys are used" do
      no_used = Set.new
      detector = described_class.new(all_keys, no_used)
      detector.detect

      expect(detector.usage_percentage).to eq(0.0)
    end
  end
end
