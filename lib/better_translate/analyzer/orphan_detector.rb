# frozen_string_literal: true

module BetterTranslate
  module Analyzer
    # Detects orphan i18n keys (keys defined but never used in code)
    #
    # @example Basic usage
    #   all_keys = { "users.greeting" => "Hello", "orphan" => "Unused" }
    #   used_keys = Set.new(["users.greeting"])
    #
    #   detector = OrphanDetector.new(all_keys, used_keys)
    #   orphans = detector.detect
    #   #=> ["orphan"]
    #
    class OrphanDetector
      # @return [Hash] All translation keys with their values
      attr_reader :all_keys

      # @return [Set] Keys that are used in code
      attr_reader :used_keys

      # @return [Array<String>] Orphan keys (not used in code)
      attr_reader :orphans

      # Initialize detector
      #
      # @param all_keys [Hash] All translation keys from YAML files
      # @param used_keys [Set] Keys found in code
      #
      def initialize(all_keys, used_keys)
        @all_keys = all_keys
        @used_keys = used_keys
        @orphans = []
      end

      # Detect orphan keys
      #
      # Compares all keys with used keys and identifies those that are never referenced.
      #
      # @return [Array<String>] List of orphan key names
      #
      # @example
      #   detector.detect
      #   #=> ["orphan_key", "another.orphan"]
      #
      def detect
        @orphans = all_keys.keys.reject { |key| used_keys.include?(key) }
      end

      # Get count of orphan keys
      #
      # @return [Integer] Number of orphan keys
      #
      def orphan_count
        @orphans.size
      end

      # Get details of orphan keys with their values
      #
      # @return [Hash] Hash of orphan keys and their translation values
      #
      # @example
      #   detector.orphan_details
      #   #=> { "orphan_key" => "This is never used" }
      #
      def orphan_details
        # @type var result: Hash[String, untyped]
        result = {}
        @orphans.each do |key|
          result[key] = all_keys[key]
        end
        result
      end

      # Calculate usage percentage
      #
      # @return [Float] Percentage of keys that are used (0.0 to 100.0)
      #
      # @example
      #   detector.usage_percentage
      #   #=> 75.0  # 6 out of 8 keys are used
      #
      def usage_percentage
        return 0.0 if all_keys.empty?

        used_count = all_keys.size - @orphans.size
        (used_count.to_f / all_keys.size * 100).round(1).to_f
      end
    end
  end
end
