# frozen_string_literal: true

RSpec.describe BetterTranslate::VariableExtractor do
  describe "#extract" do
    it "extracts Rails I18n variables" do
      extractor = described_class.new("Hello %<name>s, you have %<count>s messages")
      safe_text = extractor.extract

      expect(safe_text).to eq("Hello __VAR_0__, you have __VAR_1__ messages")
      expect(extractor.variables).to eq(["%<name>s", "%<count>s"])
      expect(extractor.variable_count).to eq(2)
    end

    it "extracts I18n.js variables" do
      extractor = described_class.new("Welcome {{user}}!")
      safe_text = extractor.extract

      expect(safe_text).to eq("Welcome __VAR_0__!")
      expect(extractor.variables).to eq(["{{user}}"])
    end

    it "extracts ES6 template variables" do
      extractor = described_class.new("Total: ${amount}")
      safe_text = extractor.extract

      expect(safe_text).to eq("Total: __VAR_0__")
      expect(extractor.variables).to eq(["${amount}"])
    end

    it "extracts simple brace variables" do
      extractor = described_class.new("Hello {name}")
      safe_text = extractor.extract

      expect(safe_text).to eq("Hello __VAR_0__")
      expect(extractor.variables).to eq(["{name}"])
    end

    it "extracts mixed variable formats" do
      text = "Hi %<name>s, you have {{count}} items (${total})"
      extractor = described_class.new(text)
      safe_text = extractor.extract

      expect(extractor.variables).to eq(["%<name>s", "{{count}}", "${total}"])
      expect(safe_text).to eq("Hi __VAR_0__, you have __VAR_1__ items (__VAR_2__)")
    end

    it "handles text without variables" do
      extractor = described_class.new("Hello world")
      safe_text = extractor.extract

      expect(safe_text).to eq("Hello world")
      expect(extractor.variables).to be_empty
    end

    it "handles empty text" do
      extractor = described_class.new("")
      expect(extractor.extract).to eq("")
      expect(extractor.variables).to be_empty
    end
  end

  describe "#restore" do
    it "restores variables to original format" do
      extractor = described_class.new("Hello %<name>s")
      extractor.extract
      translated = "Ciao __VAR_0__"

      restored = extractor.restore(translated)
      expect(restored).to eq("Ciao %<name>s")
    end

    it "restores multiple variables in correct positions" do
      extractor = described_class.new("You have %<count>s messages from {{user}}")
      extractor.extract
      # Simulated translation that reorders placeholders
      translated = "__VAR_1__ ti ha inviato __VAR_0__ messaggi"

      restored = extractor.restore(translated)
      expect(restored).to eq("{{user}} ti ha inviato %<count>s messaggi")
    end

    it "raises error in strict mode if variable is missing" do
      extractor = described_class.new("Hello %<name>s")
      extractor.extract
      translated = "Ciao" # Missing variable

      expect do
        extractor.restore(translated, strict: true)
      end.to raise_error(BetterTranslate::ValidationError, /Missing variables: %<name>s/)
    end

    it "does not raise in non-strict mode if variable is missing" do
      extractor = described_class.new("Hello %<name>s")
      extractor.extract
      translated = "Ciao"

      expect do
        extractor.restore(translated, strict: false)
      end.not_to raise_error

      expect(extractor.restore(translated, strict: false)).to eq("Ciao")
    end

    it "detects unexpected variables" do
      extractor = described_class.new("Hello world")
      extractor.extract
      translated = "Ciao %<name>s" # Unexpected variable added

      expect do
        extractor.restore(translated, strict: true)
      end.to raise_error(BetterTranslate::ValidationError, /Unexpected variables: %<name>s/)
    end
  end

  describe ".find_variables" do
    it "finds all variables in text" do
      text = "Hi %<name>s, {{count}} items"
      variables = described_class.find_variables(text)

      expect(variables).to contain_exactly("%<name>s", "{{count}}")
    end

    it "returns empty array for text without variables" do
      expect(described_class.find_variables("Hello world")).to eq([])
    end
  end

  describe ".contains_variables?" do
    it "returns true if variables are present" do
      expect(described_class.contains_variables?("Hello %<name>s")).to be true
      expect(described_class.contains_variables?("Hi {{user}}")).to be true
    end

    it "returns false if no variables" do
      expect(described_class.contains_variables?("Hello world")).to be false
    end
  end

  describe "#validate_variables!" do
    it "passes validation if all variables are present" do
      extractor = described_class.new("Hello %<name>s")
      extractor.extract

      expect do
        extractor.validate_variables!("Ciao %<name>s")
      end.not_to raise_error
    end

    it "fails validation if variables are missing" do
      extractor = described_class.new("Hello %<name>s and %<title>s")
      extractor.extract

      expect do
        extractor.validate_variables!("Ciao %<name>s")
      end.to raise_error(BetterTranslate::ValidationError)
    end
  end

  describe "full extraction-restoration cycle" do
    it "preserves Rails annotated format exactly" do
      text = "Hello %<name>s, you have %<count>d messages"
      extractor = described_class.new(text)
      extracted = extractor.extract
      restored = extractor.restore(extracted)

      expect(restored).to eq(text)
    end

    it "preserves Rails template format exactly" do
      text = "Hello %{name}, you have %{count} messages"
      extractor = described_class.new(text)
      extracted = extractor.extract
      restored = extractor.restore(extracted)

      expect(restored).to eq(text)
    end

    it "preserves mixed variable formats exactly" do
      text = "Hi %<name>s, you have {{count}} items (${total})"
      extractor = described_class.new(text)
      extracted = extractor.extract
      restored = extractor.restore(extracted)

      expect(restored).to eq(text)
    end
  end
end
