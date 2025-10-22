# frozen_string_literal: true

module BetterTranslate
  # Tracks and displays translation progress
  #
  # Shows real-time progress updates with colored console output.
  #
  # @example Basic usage
  #   tracker = ProgressTracker.new(enabled: true)
  #   tracker.update(language: "Italian", current_key: "greeting", progress: 50.0)
  #   tracker.complete("Italian", 100)
  #
  class ProgressTracker
    # @return [Boolean] Whether to show progress
    attr_reader :enabled

    # Initialize progress tracker
    #
    # @param enabled [Boolean] Whether to show progress (default: true)
    #
    # @example
    #   tracker = ProgressTracker.new(enabled: true)
    #
    def initialize(enabled: true)
      @enabled = enabled
      @start_time = Time.now
    end

    # Update progress
    #
    # @param language [String] Current language being translated
    # @param current_key [String] Current translation key
    # @param progress [Float] Progress percentage (0-100)
    # @return [void]
    #
    # @example
    #   tracker.update(language: "Italian", current_key: "nav.home", progress: 75.5)
    #
    def update(language:, current_key:, progress:)
      return unless enabled

      elapsed = Time.now - @start_time
      estimated_total = progress.positive? ? elapsed / (progress / 100.0) : 0
      remaining = estimated_total - elapsed

      message = format(
        "\r[BetterTranslate] %s | %s | %.1f%% | Elapsed: %s | Remaining: ~%s",
        colorize(language, :cyan),
        truncate(current_key, 40),
        progress,
        format_time(elapsed),
        format_time(remaining)
      )

      print message
      $stdout.flush

      puts "" if progress >= 100.0 # New line when complete
    end

    # Mark translation as complete for a language
    #
    # @param language [String] Language name
    # @param total_strings [Integer] Total number of strings translated
    # @return [void]
    #
    # @example
    #   tracker.complete("Italian", 150)
    #
    def complete(language, total_strings)
      return unless enabled

      elapsed = Time.now - @start_time
      puts colorize("✓ #{language}: #{total_strings} strings translated in #{format_time(elapsed)}", :green)
    end

    # Display an error
    #
    # @param language [String] Language name
    # @param error [StandardError] The error that occurred
    # @return [void]
    #
    # @example
    #   tracker.error("Italian", StandardError.new("API error"))
    #
    def error(language, error)
      return unless enabled

      puts colorize("✗ #{language}: #{error.message}", :red)
    end

    # Reset the progress tracker
    #
    # @return [void]
    #
    # @example
    #   tracker.reset
    #
    def reset
      @start_time = Time.now
    end

    private

    # Format time in human-readable format
    #
    # @param seconds [Float] Seconds
    # @return [String] Formatted time
    # @api private
    #
    def format_time(seconds)
      return "0s" if seconds <= 0

      minutes = (seconds / 60).to_i
      secs = (seconds % 60).to_i

      if minutes.positive?
        "#{minutes}m #{secs}s"
      else
        "#{secs}s"
      end
    end

    # Truncate text to max length
    #
    # @param text [String] Text to truncate
    # @param max_length [Integer] Maximum length
    # @return [String] Truncated text
    # @api private
    #
    def truncate(text, max_length)
      return text if text.length <= max_length

      "#{text[0...(max_length - 3)]}..."
    end

    # Colorize text for terminal output
    #
    # @param text [String] Text to colorize
    # @param color [Symbol] Color name (:red, :green, :cyan)
    # @return [String] Colorized text
    # @api private
    #
    def colorize(text, color)
      return text unless $stdout.tty?

      colors = {
        red: "\e[31m",
        green: "\e[32m",
        cyan: "\e[36m",
        reset: "\e[0m"
      }

      "#{colors[color]}#{text}#{colors[:reset]}"
    end
  end
end
