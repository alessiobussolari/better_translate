# frozen_string_literal: true

RSpec.describe BetterTranslate::Utils::HashFlattener do
  describe ".flatten" do
    it "flattens a simple nested hash" do
      nested = {
        "user" => {
          "name" => "John",
          "age" => 30
        }
      }

      result = described_class.flatten(nested)

      expect(result).to eq({
                             "user.name" => "John",
                             "user.age" => 30
                           })
    end

    it "flattens deeply nested hashes" do
      nested = {
        "app" => {
          "config" => {
            "database" => {
              "host" => "localhost",
              "port" => 5432
            }
          }
        }
      }

      result = described_class.flatten(nested)

      expect(result).to eq({
                             "app.config.database.host" => "localhost",
                             "app.config.database.port" => 5432
                           })
    end

    it "handles empty hashes" do
      expect(described_class.flatten({})).to eq({})
    end

    it "handles hashes with no nesting" do
      flat = { "key1" => "value1", "key2" => "value2" }
      expect(described_class.flatten(flat)).to eq(flat)
    end

    it "uses custom separator" do
      nested = { "user" => { "name" => "John" } }
      result = described_class.flatten(nested, "", "/")

      expect(result).to eq({ "user/name" => "John" })
    end

    it "preserves non-hash values" do
      nested = {
        "string" => "value",
        "number" => 42,
        "boolean" => true,
        "nil" => nil,
        "array" => [1, 2, 3]
      }

      result = described_class.flatten(nested)

      expect(result["string"]).to eq("value")
      expect(result["number"]).to eq(42)
      expect(result["boolean"]).to be true
      expect(result["nil"]).to be_nil
      expect(result["array"]).to eq([1, 2, 3])
    end
  end

  describe ".unflatten" do
    it "unflattens a flat hash" do
      flat = {
        "user.name" => "John",
        "user.age" => 30
      }

      result = described_class.unflatten(flat)

      expect(result).to eq({
                             "user" => {
                               "name" => "John",
                               "age" => 30
                             }
                           })
    end

    it "unflattens deeply nested keys" do
      flat = {
        "app.config.database.host" => "localhost",
        "app.config.database.port" => 5432
      }

      result = described_class.unflatten(flat)

      expect(result).to eq({
                             "app" => {
                               "config" => {
                                 "database" => {
                                   "host" => "localhost",
                                   "port" => 5432
                                 }
                               }
                             }
                           })
    end

    it "handles empty hashes" do
      expect(described_class.unflatten({})).to eq({})
    end

    it "handles keys with no dots" do
      flat = { "key1" => "value1", "key2" => "value2" }
      expect(described_class.unflatten(flat)).to eq(flat)
    end

    it "uses custom separator" do
      flat = { "user/name" => "John" }
      result = described_class.unflatten(flat, "/")

      expect(result).to eq({ "user" => { "name" => "John" } })
    end

    it "preserves non-hash values" do
      flat = {
        "string" => "value",
        "number" => 42,
        "boolean" => true,
        "nil" => nil,
        "array" => [1, 2, 3]
      }

      result = described_class.unflatten(flat)

      expect(result["string"]).to eq("value")
      expect(result["number"]).to eq(42)
      expect(result["boolean"]).to be true
      expect(result["nil"]).to be_nil
      expect(result["array"]).to eq([1, 2, 3])
    end
  end

  describe "round-trip" do
    it "preserves data through flatten and unflatten" do
      original = {
        "app" => {
          "name" => "BetterTranslate",
          "version" => "1.0.0",
          "config" => {
            "cache" => {
              "enabled" => true,
              "ttl" => 3600
            }
          }
        }
      }

      flattened = described_class.flatten(original)
      restored = described_class.unflatten(flattened)

      expect(restored).to eq(original)
    end
  end
end
