# frozen_string_literal: true

RSpec.describe BetterTranslate::ProgressTracker do
  describe "#initialize" do
    it "sets enabled to true by default" do
      tracker = described_class.new
      expect(tracker.enabled).to be true
    end

    it "accepts enabled parameter" do
      tracker = described_class.new(enabled: false)
      expect(tracker.enabled).to be false
    end
  end

  describe "#update" do
    context "when enabled" do
      subject(:tracker) { described_class.new(enabled: true) }

      it "prints progress to stdout" do
        expect do
          tracker.update(language: "Italian", current_key: "greeting", progress: 50.0)
        end.to output(/Italian.*greeting.*50\.0%/).to_stdout
      end

      it "prints newline when progress is 100%" do
        expect do
          tracker.update(language: "Italian", current_key: "greeting", progress: 100.0)
        end.to output(/\n/).to_stdout
      end

      it "shows elapsed and remaining time" do
        expect do
          tracker.update(language: "Italian", current_key: "greeting", progress: 50.0)
        end.to output(/Elapsed.*Remaining/).to_stdout
      end

      it "truncates long keys" do
        long_key = "a" * 100
        expect do
          tracker.update(language: "Italian", current_key: long_key, progress: 50.0)
        end.to output(/\.\.\./).to_stdout
      end
    end

    context "when disabled" do
      subject(:tracker) { described_class.new(enabled: false) }

      it "does not print anything" do
        expect do
          tracker.update(language: "Italian", current_key: "greeting", progress: 50.0)
        end.not_to output.to_stdout
      end
    end
  end

  describe "#complete" do
    context "when enabled" do
      subject(:tracker) { described_class.new(enabled: true) }

      it "prints completion message" do
        expect do
          tracker.complete("Italian", 100)
        end.to output(/✓ Italian: 100 strings translated/).to_stdout
      end

      it "shows elapsed time" do
        expect do
          tracker.complete("Italian", 100)
        end.to output(/in \d+[ms]/).to_stdout
      end
    end

    context "when disabled" do
      subject(:tracker) { described_class.new(enabled: false) }

      it "does not print anything" do
        expect do
          tracker.complete("Italian", 100)
        end.not_to output.to_stdout
      end
    end
  end

  describe "#error" do
    let(:error) { StandardError.new("Test error") }

    context "when enabled" do
      subject(:tracker) { described_class.new(enabled: true) }

      it "prints error message" do
        expect do
          tracker.error("Italian", error)
        end.to output(/✗ Italian: Test error/).to_stdout
      end
    end

    context "when disabled" do
      subject(:tracker) { described_class.new(enabled: false) }

      it "does not print anything" do
        expect do
          tracker.error("Italian", error)
        end.not_to output.to_stdout
      end
    end
  end

  describe "#reset" do
    it "resets the start time" do
      tracker = described_class.new(enabled: true)
      tracker.reset
      # After reset, should not raise error
      expect { tracker.update(language: "Italian", current_key: "test", progress: 50.0) }.not_to raise_error
    end
  end

  describe "private methods" do
    subject(:tracker) { described_class.new }

    describe "#format_time" do
      it "formats seconds only" do
        result = tracker.send(:format_time, 45)
        expect(result).to eq("45s")
      end

      it "formats minutes and seconds" do
        result = tracker.send(:format_time, 125)
        expect(result).to eq("2m 5s")
      end

      it "handles zero or negative time" do
        result = tracker.send(:format_time, 0)
        expect(result).to eq("0s")
      end
    end

    describe "#truncate" do
      it "returns text as is if shorter than max" do
        result = tracker.send(:truncate, "short", 10)
        expect(result).to eq("short")
      end

      it "truncates long text with ellipsis" do
        result = tracker.send(:truncate, "this is a very long text", 10)
        expect(result).to eq("this is...")
      end
    end
  end
end
