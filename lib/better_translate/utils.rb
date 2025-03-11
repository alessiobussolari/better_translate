# frozen_string_literal: true

module BetterTranslate
  # Utility class providing helper methods for logging and metrics tracking.
  # Used throughout the BetterTranslate gem to standardize logging and performance monitoring.
  class Utils
    class << self
      
      # Logs a message using the Rails logger if available, otherwise prints to standard output.
      # Provides a consistent logging interface across different environments.
      #
      # @param message [String, nil] The message to log
      # @return [void]
      def logger(message: nil)
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.info message
        else
          puts message
        end
      end

      # Tracks a metric with the given name and value.
      # Stores metrics in memory with timestamps for performance analysis.
      # Automatically limits each metric type to the most recent 1000 entries.
      #
      # @param name [Symbol, String] The name of the metric to track
      # @param value [Numeric] The value to record for this metric
      # @return [void]
      def track_metric(name, value)
        @metrics ||= {}
        @metrics[name] ||= []
        @metrics[name] << { value: value, timestamp: Time.now }

        # Mantieni solo le ultime 1000 metriche per tipo
        @metrics[name] = @metrics[name].last(1000) if @metrics[name].size > 1000
      end

      # Retrieves all tracked metrics.
      # Returns a hash where keys are metric names and values are arrays of recorded values with timestamps.
      #
      # @return [Hash] The collected metrics or an empty hash if no metrics have been tracked
      def get_metrics
        @metrics || {}
      end

      # Clears all tracked metrics.
      # Useful for resetting metrics between translation jobs or testing.
      #
      # @return [Hash] An empty hash representing the cleared metrics
      def clear_metrics
        @metrics = {}
      end
    end
  end
end
