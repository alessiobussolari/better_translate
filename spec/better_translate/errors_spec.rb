# frozen_string_literal: true

RSpec.describe BetterTranslate::Error do
  describe "#initialize" do
    it "accepts a message" do
      error = described_class.new("Test error")
      expect(error.message).to eq("Test error")
    end

    it "accepts context as a keyword argument" do
      error = described_class.new("Test error", context: { key: "value" })
      expect(error.context).to eq({ key: "value" })
    end

    it "has empty context by default" do
      error = described_class.new("Test error")
      expect(error.context).to eq({})
    end
  end
end

RSpec.describe BetterTranslate::ConfigurationError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end

  it "supports context" do
    error = described_class.new("Config error", context: { provider: "chatgpt" })
    expect(error.context).to eq({ provider: "chatgpt" })
  end
end

RSpec.describe BetterTranslate::ValidationError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::TranslationError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::ProviderError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::ApiError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::RateLimitError do
  it "inherits from BetterTranslate::ApiError" do
    expect(described_class).to be < BetterTranslate::ApiError
  end

  it "inherits from BetterTranslate::Error indirectly" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::FileError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::YamlError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end

RSpec.describe BetterTranslate::ProviderNotFoundError do
  it "inherits from BetterTranslate::Error" do
    expect(described_class).to be < BetterTranslate::Error
  end
end
