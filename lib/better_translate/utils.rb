# frozen_string_literal: true

# lib/better_seeder/utils.rb
#
# = BetterSeeder::Utils
#
# This module provides utility methods for seed management. In particular,
# allows transforming class names into snake_case format with the "_structure.rb" suffix,
# manage log messages and configure the logger level for ActiveRecord.

module BetterTranslate
  class Utils
    class << self
      ##
      # Logs a message using the Rails logger if available, otherwise prints it to standard output.
      #
      # ==== Parametri
      # * +message+ - The message to log (can be a string or nil).
      #
      # ==== Ritorno
      # Does not return a significant value.
      #
      def logger(message: nil)
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.info message
        else
          puts message
        end
      end

      def track_metric(name, value)
        @metrics ||= {}
        @metrics[name] ||= []
        @metrics[name] << { value: value, timestamp: Time.now }

        # Mantieni solo le ultime 1000 metriche per tipo
        @metrics[name] = @metrics[name].last(1000) if @metrics[name].size > 1000
      end

      def get_metrics
        @metrics || {}
      end

      def clear_metrics
        @metrics = {}
      end
    end
  end
end
