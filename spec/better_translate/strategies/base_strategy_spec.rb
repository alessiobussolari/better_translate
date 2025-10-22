# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Strategies::BaseStrategy do
  let(:config) do
    config = BetterTranslate::Configuration.new
    config.provider = :chatgpt
    config.openai_key = "test_key"
    config.source_language = "en"
    config.target_languages = [{ short_name: "it", name: "Italian" }]
    config.input_file = __FILE__
    config.output_folder = Dir.tmpdir
    config
  end

  let(:provider) { BetterTranslate::Providers::ChatGPTProvider.new(config) }
  let(:progress_tracker) { BetterTranslate::ProgressTracker.new(enabled: false) }

  subject(:strategy) { described_class.new(config, provider, progress_tracker) }

  describe "#initialize" do
    it "sets config" do
      expect(strategy.config).to eq(config)
    end

    it "sets provider" do
      expect(strategy.provider).to eq(provider)
    end

    it "sets progress_tracker" do
      expect(strategy.progress_tracker).to eq(progress_tracker)
    end
  end

  describe "#translate" do
    it "raises NotImplementedError" do
      expect do
        strategy.translate({}, "it", "Italian")
      end.to raise_error(NotImplementedError, /must implement #translate/)
    end
  end
end
