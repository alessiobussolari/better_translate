# frozen_string_literal: true

require "better_translate"
require "webmock/rspec"
require "dotenv"

# Carica le variabili d'ambiente dal file .env se presente
Dotenv.load(".env")

# Carica i supporti per i test
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Includi gli helper nei test
  config.include TranslationHelper, type: :provider
  config.include TranslationHelper, type: :integration

  # Tag per i test che richiedono API key
  config.before(:each, :api_key) do
    skip "API key required for this test" unless ENV["OPENAI_API_KEY"] || ENV["GEMINI_API_KEY"]
  end

  # Configura WebMock
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.after(:each) do
    WebMock.allow_net_connect!
  end
end
