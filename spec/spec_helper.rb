# frozen_string_literal: true

require "better_translate"
require "vcr"
require "webmock/rspec"
require "dotenv/load"
require "json"

# Disable HTML escaping in JSON to ensure consistent encoding
# This prevents %<name>s from becoming %\u003cname\u003es
JSON.instance_eval do
  def generate(obj, opts = nil)
    opts = (opts || JSON::SAFE_STATE_PROTOTYPE.dup).merge(escape_html: false)
    super(obj, opts)
  end
end

# Configure VCR for recording API interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data from cassettes
  config.filter_sensitive_data("<OPENAI_API_KEY>") { ENV.fetch("OPENAI_API_KEY", nil) }
  config.filter_sensitive_data("<GEMINI_API_KEY>") { ENV.fetch("GEMINI_API_KEY", nil) }
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV.fetch("ANTHROPIC_API_KEY", nil) }

  # Default to :once mode (use existing cassettes, record new ones)
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri body]
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
