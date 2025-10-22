# frozen_string_literal: true

module BetterTranslate
  # Translation strategy implementations
  module Strategies
    # Base class for translation strategies
    #
    # @abstract Subclasses must implement {#translate}
    #
    # @example Creating a custom strategy
    #   class MyStrategy < BaseStrategy
    #     def translate(strings, target_lang_code, target_lang_name)
    #       # Custom translation logic
    #     end
    #   end
    #
    class BaseStrategy
      # @return [Configuration] Configuration object
      attr_reader :config

      # @return [Providers::BaseHttpProvider] Translation provider
      attr_reader :provider

      # @return [ProgressTracker] Progress tracker
      attr_reader :progress_tracker

      # Initialize the strategy
      #
      # @param config [Configuration] Configuration object
      # @param provider [Providers::BaseHttpProvider] Translation provider
      # @param progress_tracker [ProgressTracker] Progress tracker
      #
      # @example
      #   strategy = BaseStrategy.new(config, provider, tracker)
      #
      def initialize(config, provider, progress_tracker)
        @config = config
        @provider = provider
        @progress_tracker = progress_tracker
      end

      # Translate strings
      #
      # @param strings [Hash] Flattened hash of strings to translate
      # @param target_lang_code [String] Target language code
      # @param target_lang_name [String] Target language name
      # @return [Hash] Translated strings (flattened)
      # @raise [NotImplementedError] Must be implemented by subclasses
      #
      # @example
      #   translated = strategy.translate(strings, "it", "Italian")
      #
      def translate(strings, target_lang_code, target_lang_name)
        raise NotImplementedError, "#{self.class} must implement #translate"
      end
    end
  end
end
