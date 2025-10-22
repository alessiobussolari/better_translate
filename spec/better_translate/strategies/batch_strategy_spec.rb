# frozen_string_literal: true

RSpec.describe BetterTranslate::Strategies::BatchStrategy do
  let(:config) { BetterTranslate::Configuration.new }
  let(:provider) { instance_double(BetterTranslate::Providers::ChatGPTProvider) }
  let(:progress_tracker) { instance_double(BetterTranslate::ProgressTracker) }
  let(:strategy) { described_class.new(config, provider, progress_tracker) }

  describe "BATCH_SIZE" do
    it "is set to 10" do
      expect(described_class::BATCH_SIZE).to eq(10)
    end
  end

  describe "#translate" do
    let(:target_lang_code) { "it" }
    let(:target_lang_name) { "Italian" }

    context "with empty hash" do
      it "returns empty hash without calling provider" do
        strings = {}

        expect(provider).not_to receive(:translate_batch)
        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result).to eq({})
      end

      it "does not update progress tracker" do
        strings = {}

        expect(progress_tracker).not_to receive(:update)
        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with exactly one batch (10 strings)" do
      it "translates all strings in one batch" do
        strings = (1..10).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_batch)
          .with(strings.values, target_lang_code, target_lang_name)
          .and_return((1..10).map { |i| "Translated #{i}" })

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(10)
        expect(result["key_1"]).to eq("Translated 1")
        expect(result["key_10"]).to eq("Translated 10")
      end

      it "updates progress to 100% for single batch" do
        strings = (1..10).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(provider).to receive(:translate_batch).and_return(Array.new(10, "translated"))
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 1/1",
          progress: 100.0
        )

        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with exactly two batches (20 strings)" do
      it "translates strings in two batches" do
        strings = (1..20).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch)
          .with(strings.values[0..9], target_lang_code, target_lang_name)
          .and_return((1..10).map { |i| "Translated #{i}" })
        allow(provider).to receive(:translate_batch)
          .with(strings.values[10..19], target_lang_code, target_lang_name)
          .and_return((11..20).map { |i| "Translated #{i}" })

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(20)
        expect(provider).to have_received(:translate_batch).twice
      end

      it "updates progress at 50% and 100%" do
        strings = (1..20).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(provider).to receive(:translate_batch).and_return(Array.new(10, "translated"))

        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 1/2",
          progress: 50.0
        ).ordered
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 2/2",
          progress: 100.0
        ).ordered

        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with incomplete last batch (25 strings)" do
      it "handles last incomplete batch correctly" do
        strings = (1..25).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_batch)
          .with(strings.values[0..9], target_lang_code, target_lang_name)
          .and_return((1..10).map { |i| "Translated #{i}" })
        expect(provider).to receive(:translate_batch)
          .with(strings.values[10..19], target_lang_code, target_lang_name)
          .and_return((11..20).map { |i| "Translated #{i}" })
        expect(provider).to receive(:translate_batch)
          .with(strings.values[20..24], target_lang_code, target_lang_name)
          .and_return((21..25).map { |i| "Translated #{i}" })

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(25)
        expect(result["key_1"]).to eq("Translated 1")
        expect(result["key_25"]).to eq("Translated 25")
      end

      it "updates progress correctly for 3 batches" do
        strings = (1..25).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(provider).to receive(:translate_batch) { |batch| Array.new(batch.size, "translated") }

        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 1/3",
          progress: 33.3
        ).ordered
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 2/3",
          progress: 66.7
        ).ordered
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "Batch 3/3",
          progress: 100.0
        ).ordered

        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with 50 strings (threshold for batch strategy)" do
      it "translates all 50 strings in 5 batches" do
        strings = (1..50).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(50)
        expect(provider).to have_received(:translate_batch).exactly(5).times
      end

      it "updates progress from 20% to 100%" do
        strings = (1..50).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }
        updates = []

        allow(provider).to receive(:translate_batch) { |batch| Array.new(batch.size, "translated") }
        allow(progress_tracker).to receive(:update) { |args| updates << args }

        strategy.translate(strings, target_lang_code, target_lang_name)

        expect(updates.size).to eq(5)
        expect(updates.first[:progress]).to eq(20.0)
        expect(updates.last[:progress]).to eq(100.0)
      end
    end

    context "with large dataset (100 strings)" do
      it "translates all 100 strings in 10 batches" do
        strings = (1..100).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(100)
        expect(provider).to have_received(:translate_batch).exactly(10).times
      end

      it "maintains correct key-value mapping across all batches" do
        strings = (1..100).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        # Verify first, middle, and last items
        expect(result["key_1"]).to eq("translated_Text 1")
        expect(result["key_50"]).to eq("translated_Text 50")
        expect(result["key_100"]).to eq("translated_Text 100")

        # Verify all keys present
        expect(result.keys).to eq((1..100).map { |i| "key_#{i}" })
      end
    end

    context "with very large dataset (1000 strings)" do
      it "translates all 1000 strings in 100 batches" do
        strings = (1..1000).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| Array.new(batch.size, "translated") }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(1000)
        expect(provider).to have_received(:translate_batch).exactly(100).times
      end
    end

    context "key order preservation" do
      it "maintains order of keys across batches" do
        strings = {
          "z_last" => "Last",
          "a_first" => "First",
          "m_middle" => "Middle",
          "x_another" => "Another",
          "b_second" => "Second",
          "y_yet" => "Yet",
          "c_third" => "Third",
          "w_one" => "One",
          "d_fourth" => "Fourth",
          "v_more" => "More",
          "e_fifth" => "Fifth"
        }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.keys).to eq(strings.keys)
      end
    end

    context "error handling" do
      it "propagates provider errors from first batch" do
        strings = (1..20).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_batch)
          .and_raise(BetterTranslate::TranslationError.new("API error"))

        expect do
          strategy.translate(strings, target_lang_code, target_lang_name)
        end.to raise_error(BetterTranslate::TranslationError, "API error")
      end

      it "stops translation on error in middle batch" do
        strings = (1..30).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }
        call_count = 0

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) do
          call_count += 1
          raise BetterTranslate::TranslationError, "API error" unless call_count == 1

          Array.new(10, "translated")
        end

        expect do
          strategy.translate(strings, target_lang_code, target_lang_name)
        end.to raise_error(BetterTranslate::TranslationError)

        # Should only have called translate_batch twice (second one failed)
        expect(call_count).to eq(2)
      end
    end

    context "with special characters and Unicode" do
      it "handles batches with special characters" do
        strings = (1..15).each_with_object({}) do |i, h|
          h["key_#{i}"] = "Text #{i} with \"quotes\" and 'apostrophes'"
        end

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(15)
        expect(result.values.all? { |v| v.start_with?("translated_") }).to be true
      end

      it "handles batches with Unicode characters" do
        strings = (1..15).each_with_object({}) do |i, h|
          h["key_#{i}"] = "Text #{i} 👋 🌍 你好 مرحبا"
        end

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_batch) { |batch| batch.map { |text| "translated_#{text}" } }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(15)
      end
    end

    context "with single string (edge case)" do
      it "translates single string in one batch" do
        strings = { "greeting" => "Hello" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_batch)
          .with(["Hello"], target_lang_code, target_lang_name)
          .and_return(["Ciao"])

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result).to eq({ "greeting" => "Ciao" })
      end
    end
  end
end
