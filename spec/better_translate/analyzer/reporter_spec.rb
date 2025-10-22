# frozen_string_literal: true

require "tmpdir"

RSpec.describe BetterTranslate::Analyzer::Reporter do
  let(:orphan_keys) { ["orphan_key", "another.orphan", "unused.translation"] }
  let(:orphan_details) do
    {
      "orphan_key" => "This is never used",
      "another.orphan" => "Another unused key",
      "unused.translation" => "Some text"
    }
  end
  let(:total_keys) { 10 }
  let(:used_keys) { 7 }
  let(:usage_percentage) { 70.0 }

  describe "#generate" do
    context "text format" do
      it "generates a text report with orphan keys" do
        reporter = described_class.new(
          orphans: orphan_keys,
          orphan_details: orphan_details,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage,
          format: :text
        )

        report = reporter.generate

        expect(report).to be_a(String)
        expect(report).to include("Orphan Keys Analysis")
        expect(report).to include("orphan_key")
        expect(report).to include("another.orphan")
        expect(report).to include("unused.translation")
      end

      it "includes statistics in the report" do
        reporter = described_class.new(
          orphans: orphan_keys,
          orphan_details: orphan_details,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage,
          format: :text
        )

        report = reporter.generate

        expect(report).to include("Total keys: 10")
        expect(report).to include("Used keys: 7")
        expect(report).to include("Orphan keys: 3")
        expect(report).to include("Usage: 70.0%")
      end

      it "shows a success message when no orphans found" do
        reporter = described_class.new(
          orphans: [],
          orphan_details: {},
          total_keys: 10,
          used_keys: 10,
          usage_percentage: 100.0,
          format: :text
        )

        report = reporter.generate

        expect(report).to include("No orphan keys found")
        expect(report).to include("100.0%")
      end
    end

    context "JSON format" do
      it "generates a JSON report" do
        reporter = described_class.new(
          orphans: orphan_keys,
          orphan_details: orphan_details,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage,
          format: :json
        )

        report = reporter.generate
        data = JSON.parse(report)

        expect(data["orphans"]).to eq(orphan_keys)
        expect(data["total_keys"]).to eq(total_keys)
        expect(data["used_keys"]).to eq(used_keys)
        expect(data["orphan_count"]).to eq(3)
        expect(data["usage_percentage"]).to eq(usage_percentage)
      end

      it "includes orphan details in JSON" do
        reporter = described_class.new(
          orphans: orphan_keys,
          orphan_details: orphan_details,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage,
          format: :json
        )

        report = reporter.generate
        data = JSON.parse(report)

        expect(data["orphan_details"]).to eq(orphan_details)
      end
    end

    context "CSV format" do
      it "generates a CSV report" do
        reporter = described_class.new(
          orphans: orphan_keys,
          orphan_details: orphan_details,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage,
          format: :csv
        )

        report = reporter.generate

        expect(report).to include("Key,Value")
        expect(report).to include("orphan_key,This is never used")
        expect(report).to include("another.orphan,Another unused key")
      end
    end
  end

  describe "#save_to_file" do
    it "saves report to a file" do
      reporter = described_class.new(
        orphans: orphan_keys,
        orphan_details: orphan_details,
        total_keys: total_keys,
        used_keys: used_keys,
        usage_percentage: usage_percentage,
        format: :text
      )

      output_file = File.join(Dir.tmpdir, "orphan_report.txt")

      reporter.save_to_file(output_file)

      expect(File.exist?(output_file)).to be true
      content = File.read(output_file)
      expect(content).to include("Orphan Keys Analysis")

      File.delete(output_file) if File.exist?(output_file)
    end
  end
end
