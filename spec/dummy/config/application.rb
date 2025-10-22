# frozen_string_literal: true

require "rails"
require "action_controller/railtie"
require "better_translate"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = "dummy_secret_key_base"

    # Configure I18n
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en it fr es de]
  end
end
