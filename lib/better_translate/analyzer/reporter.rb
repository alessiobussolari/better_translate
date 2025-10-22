# frozen_string_literal: true

require "json"
require "csv"

module BetterTranslate
  module Analyzer
    # Generates reports for orphan key analysis
    #
    # Supports multiple output formats: text, JSON, CSV
    #
    # @example Basic usage
    #   reporter = Reporter.new(
    #     orphans: ["orphan_key"],
    #     orphan_details: { "orphan_key" => "Unused" },
    #     total_keys: 10,
    #     used_keys: 9,
    #     usage_percentage: 90.0,
    #     format: :text
    #   )
    #   puts reporter.generate
    #
    class Reporter
      # @return [Array<String>] List of orphan keys
      attr_reader :orphans

      # @return [Hash] Orphan keys with their values
      attr_reader :orphan_details

      # @return [Integer] Total number of keys
      attr_reader :total_keys

      # @return [Integer] Number of used keys
      attr_reader :used_keys

      # @return [Float] Usage percentage
      attr_reader :usage_percentage

      # @return [Symbol] Output format (:text, :json, :csv)
      attr_reader :format

      # Initialize reporter
      #
      # @param orphans [Array<String>] List of orphan keys
      # @param orphan_details [Hash] Orphan keys with values
      # @param total_keys [Integer] Total number of keys
      # @param used_keys [Integer] Number of used keys
      # @param usage_percentage [Float] Usage percentage
      # @param format [Symbol] Output format (:text, :json, :csv)
      #
      def initialize(orphans:, orphan_details:, total_keys:, used_keys:, usage_percentage:, format: :text)
        @orphans = orphans
        @orphan_details = orphan_details
        @total_keys = total_keys
        @used_keys = used_keys
        @usage_percentage = usage_percentage
        @format = format
      end

      # Generate report in specified format
      #
      # @return [String] Generated report
      #
      def generate
        case format
        when :json
          generate_json
        when :csv
          generate_csv
        else
          generate_text
        end
      end

      # Save report to file
      #
      # @param file_path [String] Output file path
      #
      def save_to_file(file_path)
        File.write(file_path, generate)
      end

      private

      # Generate text format report
      #
      # @return [String] Text report
      #
      def generate_text
        lines = []
        lines << "=" * 60
        lines << "Orphan Keys Analysis Report"
        lines << "=" * 60
        lines << ""
        lines << "Statistics:"
        lines << "  Total keys: #{total_keys}"
        lines << "  Used keys: #{used_keys}"
        lines << "  Orphan keys: #{orphans.size}"
        lines << "  Usage: #{usage_percentage}%"
        lines << ""

        if orphans.empty?
          lines << "✓ No orphan keys found! All translation keys are being used."
        else
          lines << "Orphan Keys (#{orphans.size}):"
          lines << "-" * 60

          orphans.each do |key|
            value = orphan_details[key]
            lines << ""
            lines << "  Key: #{key}"
            lines << "  Value: #{value}" if value
          end
        end

        lines << ""
        lines << "=" * 60

        lines.join("\n")
      end

      # Generate JSON format report
      #
      # @return [String] JSON report
      #
      def generate_json
        data = {
          orphans: orphans,
          orphan_details: orphan_details,
          orphan_count: orphans.size,
          total_keys: total_keys,
          used_keys: used_keys,
          usage_percentage: usage_percentage
        }

        JSON.pretty_generate(data)
      end

      # Generate CSV format report
      #
      # @return [String] CSV report
      #
      def generate_csv
        CSV.generate do |csv|
          csv << %w[Key Value]

          orphans.each do |key|
            value = orphan_details[key]
            csv << [key, value]
          end
        end
      end
    end
  end
end
