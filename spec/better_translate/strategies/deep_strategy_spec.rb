# frozen_string_literal: true

RSpec.describe BetterTranslate::Strategies::DeepStrategy do
  let(:config) { BetterTranslate::Configuration.new }
  let(:provider) { instance_double(BetterTranslate::Providers::ChatGPTProvider) }
  let(:progress_tracker) { instance_double(BetterTranslate::ProgressTracker) }
  let(:strategy) { described_class.new(config, provider, progress_tracker) }

  describe "#translate" do
    let(:target_lang_code) { "it" }
    let(:target_lang_name) { "Italian" }

    context "with empty hash" do
      it "returns empty hash without calling provider" do
        strings = {}

        expect(provider).not_to receive(:translate_text)
        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result).to eq({})
      end

      it "does not update progress tracker" do
        strings = {}

        expect(progress_tracker).not_to receive(:update)
        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with single string" do
      it "translates the string" do
        strings = { "greeting" => "Hello" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .with("Hello", target_lang_code, target_lang_name)
          .and_return("Ciao")

        result = strategy.translate(strings, target_lang_code, target_lang_name)
        expect(result).to eq({ "greeting" => "Ciao" })
      end

      it "updates progress to 100% for single item" do
        strings = { "greeting" => "Hello" }

        allow(provider).to receive(:translate_text).and_return("Ciao")
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "greeting",
          progress: 100.0
        )

        strategy.translate(strings, target_lang_code, target_lang_name)
      end
    end

    context "with multiple strings" do
      it "translates all strings individually" do
        strings = {
          "greeting" => "Hello",
          "farewell" => "Goodbye",
          "thanks" => "Thank you"
        }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .with("Hello", target_lang_code, target_lang_name)
          .and_return("Ciao")
        expect(provider).to receive(:translate_text)
          .with("Goodbye", target_lang_code, target_lang_name)
          .and_return("Arrivederci")
        expect(provider).to receive(:translate_text)
          .with("Thank you", target_lang_code, target_lang_name)
          .and_return("Grazie")

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result).to eq({
                               "greeting" => "Ciao",
                               "farewell" => "Arrivederci",
                               "thanks" => "Grazie"
                             })
      end

      it "updates progress tracker with correct percentages" do
        strings = {
          "greeting" => "Hello",
          "farewell" => "Goodbye",
          "thanks" => "Thank you"
        }

        allow(provider).to receive(:translate_text).and_return("translated")

        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "greeting",
          progress: 33.3
        ).ordered
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "farewell",
          progress: 66.7
        ).ordered
        expect(progress_tracker).to receive(:update).with(
          language: target_lang_name,
          current_key: "thanks",
          progress: 100.0
        ).ordered

        strategy.translate(strings, target_lang_code, target_lang_name)
      end

      it "maintains order of keys" do
        strings = {
          "z_last" => "Last",
          "a_first" => "First",
          "m_middle" => "Middle"
        }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_text) do |text|
          "translated_#{text}"
        end

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.keys).to eq(%w[z_last a_first m_middle])
      end
    end

    context "with nested keys (dot notation)" do
      it "preserves nested key structure" do
        strings = {
          "messages.success" => "Success",
          "messages.error" => "Error",
          "users.greeting" => "Hello user"
        }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_text).with("Success", target_lang_code, target_lang_name)
                                                   .and_return("Successo")
        allow(provider).to receive(:translate_text).with("Error", target_lang_code, target_lang_name)
                                                   .and_return("Errore")
        allow(provider).to receive(:translate_text).with("Hello user", target_lang_code, target_lang_name)
                                                   .and_return("Ciao utente")

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result).to eq({
                               "messages.success" => "Successo",
                               "messages.error" => "Errore",
                               "users.greeting" => "Ciao utente"
                             })
      end
    end

    context "error handling" do
      it "propagates provider errors" do
        strings = { "greeting" => "Hello" }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .and_raise(BetterTranslate::TranslationError.new("API error"))

        expect do
          strategy.translate(strings, target_lang_code, target_lang_name)
        end.to raise_error(BetterTranslate::TranslationError, "API error")
      end

      it "stops translation on first error" do
        strings = {
          "greeting" => "Hello",
          "farewell" => "Goodbye",
          "thanks" => "Thank you"
        }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .with("Hello", target_lang_code, target_lang_name)
          .and_return("Ciao")
        expect(provider).to receive(:translate_text)
          .with("Goodbye", target_lang_code, target_lang_name)
          .and_raise(BetterTranslate::TranslationError.new("API error"))
        expect(provider).not_to receive(:translate_text).with("Thank you", anything, anything)

        expect do
          strategy.translate(strings, target_lang_code, target_lang_name)
        end.to raise_error(BetterTranslate::TranslationError)
      end
    end

    context "with special characters and Unicode" do
      it "handles strings with special characters" do
        strings = {
          "quote" => "Hello \"world\"",
          "apostrophe" => "It's working",
          "newline" => "Line1\nLine2"
        }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .with("Hello \"world\"", target_lang_code, target_lang_name)
          .and_return("Ciao \"mondo\"")
        expect(provider).to receive(:translate_text)
          .with("It's working", target_lang_code, target_lang_name)
          .and_return("Sta funzionando")
        expect(provider).to receive(:translate_text)
          .with("Line1\nLine2", target_lang_code, target_lang_name)
          .and_return("Linea1\nLinea2")

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result["quote"]).to eq("Ciao \"mondo\"")
        expect(result["apostrophe"]).to eq("Sta funzionando")
        expect(result["newline"]).to eq("Linea1\nLinea2")
      end

      it "handles Unicode characters" do
        strings = {
          "emoji" => "Hello 👋 World 🌍",
          "chinese" => "你好",
          "arabic" => "مرحبا"
        }

        allow(progress_tracker).to receive(:update)
        allow(provider).to receive(:translate_text) { |text| "translated_#{text}" }

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.keys).to eq(%w[emoji chinese arabic])
        expect(result.values.all? { |v| v.start_with?("translated_") }).to be true
      end
    end

    context "with very long strings" do
      it "handles strings longer than 1000 characters" do
        long_text = "Hello " * 200 # ~1200 characters
        strings = { "long_text" => long_text }

        allow(progress_tracker).to receive(:update)
        expect(provider).to receive(:translate_text)
          .with(long_text, target_lang_code, target_lang_name)
          .and_return("Ciao " * 200)

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result["long_text"]).to eq("Ciao " * 200)
      end
    end

    context "with 49 strings (threshold for deep strategy)" do
      it "translates all 49 strings with correct progress" do
        strings = (1..49).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }

        allow(provider).to receive(:translate_text) { |text| "translated_#{text}" }
        allow(progress_tracker).to receive(:update)

        result = strategy.translate(strings, target_lang_code, target_lang_name)

        expect(result.size).to eq(49)
        expect(provider).to have_received(:translate_text).exactly(49).times
      end

      it "updates progress from 2.0% to 100%" do
        strings = (1..49).each_with_object({}) { |i, h| h["key_#{i}"] = "Text #{i}" }
        updates = []

        allow(provider).to receive(:translate_text).and_return("translated")
        allow(progress_tracker).to receive(:update) { |args| updates << args }

        strategy.translate(strings, target_lang_code, target_lang_name)

        # Should have 49 progress updates
        expect(updates.size).to eq(49)

        # First update should be ~2.0% (1/49)
        expect(updates.first).to eq({
                                      language: target_lang_name,
                                      current_key: "key_1",
                                      progress: 2.0
                                    })

        # Last update should be 100.0% (49/49)
        expect(updates.last).to eq({
                                     language: target_lang_name,
                                     current_key: "key_49",
                                     progress: 100.0
                                   })
      end
    end
  end
end
