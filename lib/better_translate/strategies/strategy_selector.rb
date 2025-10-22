# frozen_string_literal: true

module BetterTranslate
  module Strategies
    # Selects the appropriate translation strategy based on content size
    #
    # @example
    #   strategy = StrategySelector.select(25, config, provider, tracker)
    #   #=> #<DeepStrategy>
    #
    #   strategy = StrategySelector.select(100, config, provider, tracker)
    #   #=> #<BatchStrategy>
    #
    class StrategySelector
      # Threshold for switching from deep to batch strategy
      DEEP_STRATEGY_THRESHOLD = 50

      # Select the appropriate strategy
      #
      # @param strings_count [Integer] Number of strings to translate
      # @param config [Configuration] Configuration object
      # @param provider [Providers::BaseHttpProvider] Translation provider
      # @param progress_tracker [ProgressTracker] Progress tracker
      # @return [BaseStrategy] Selected strategy instance
      #
      # @example Small file (deep strategy)
      #   strategy = StrategySelector.select(30, config, provider, tracker)
      #   #=> #<DeepStrategy>
      #
      # @example Large file (batch strategy)
      #   strategy = StrategySelector.select(200, config, provider, tracker)
      #   #=> #<BatchStrategy>
      #
      def self.select(strings_count, config, provider, progress_tracker)
        if strings_count < DEEP_STRATEGY_THRESHOLD
          DeepStrategy.new(config, provider, progress_tracker)
        else
          BatchStrategy.new(config, provider, progress_tracker)
        end
      end
    end
  end
end
