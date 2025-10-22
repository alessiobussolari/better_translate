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

  describe "DEEP_STRATEGY_THRESHOLD" do
    it "is set to 50" do
      expect(described_class::DEEP_STRATEGY_THRESHOLD).to eq(50)
    end
  end

  describe ".select" do
    context "with small counts" do
      it "selects DeepStrategy for 0 strings" do
        strategy = described_class.select(0, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
      end

      it "selects DeepStrategy for 1 string" do
        strategy = described_class.select(1, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
      end

      it "selects DeepStrategy for small files (< 50 strings)" do
        strategy = described_class.select(25, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
      end
    end

    context "at threshold boundary" do
      it "selects DeepStrategy at threshold - 1 (49 strings)" do
        strategy = described_class.select(49, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::DeepStrategy)
      end

      it "selects BatchStrategy at exact threshold (50 strings)" do
        strategy = described_class.select(50, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
      end

      it "selects BatchStrategy at threshold + 1 (51 strings)" do
        strategy = described_class.select(51, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
      end
    end

    context "with large counts" do
      it "selects BatchStrategy for large files (100 strings)" do
        strategy = described_class.select(100, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
      end

      it "selects BatchStrategy for very large files (1000 strings)" do
        strategy = described_class.select(1000, config, provider, progress_tracker)
        expect(strategy).to be_a(BetterTranslate::Strategies::BatchStrategy)
      end
    end

    context "strategy initialization" do
      it "passes config to DeepStrategy" do
        strategy = described_class.select(10, config, provider, progress_tracker)
        expect(strategy.instance_variable_get(:@config)).to eq(config)
      end

      it "passes provider to DeepStrategy" do
        strategy = described_class.select(10, config, provider, progress_tracker)
        expect(strategy.instance_variable_get(:@provider)).to eq(provider)
      end

      it "passes progress_tracker to DeepStrategy" do
        strategy = described_class.select(10, config, provider, progress_tracker)
        expect(strategy.instance_variable_get(:@progress_tracker)).to eq(progress_tracker)
      end

      it "passes all parameters to BatchStrategy" do
        strategy = described_class.select(100, config, provider, progress_tracker)
        expect(strategy.instance_variable_get(:@config)).to eq(config)
        expect(strategy.instance_variable_get(:@provider)).to eq(provider)
        expect(strategy.instance_variable_get(:@progress_tracker)).to eq(progress_tracker)
      end
    end
  end
end
