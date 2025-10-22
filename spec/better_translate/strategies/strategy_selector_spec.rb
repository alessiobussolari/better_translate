# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Strategies::StrategySelector do
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

  describe ".select" do
    it "selects DeepStrategy for small files (< 50 strings)" do
      strategy = described_class.select(25, config, provider, progress_tracker)
      expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
    end

    it "selects BatchStrategy for large files (>= 50 strings)" do
      strategy = described_class.select(100, config, provider, progress_tracker)
      expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
    end

    it "selects DeepStrategy at threshold - 1" do
      strategy = described_class.select(49, config, provider, progress_tracker)
      expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
    end

    it "selects BatchStrategy at threshold" do
      strategy = described_class.select(50, config, provider, progress_tracker)
      expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
    end
  end
end
