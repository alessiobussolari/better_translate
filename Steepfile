# frozen_string_literal: true

# Steep configuration for BetterTranslate
# Run with: bundle exec steep check

D = Steep::Diagnostic

target :lib do
  # Only check library files
  check "lib/**/*.rb"

  # Signature files location
  signature "sig"

  # Configure diagnostics
  configure_code_diagnostics(D::Ruby.strict)

  # Library definitions
  library "pathname"
  library "monitor"
  library "logger"
  library "set"
  library "json"
  library "yaml"
  library "securerandom"
  library "time"
  library "mutex_m"
  library "fileutils"
end
