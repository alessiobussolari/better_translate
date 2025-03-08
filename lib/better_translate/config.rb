module BetterTranslate
  class Config
    attr_accessor :provider, :default_language, :target_languages, :api_keys, :translation_method, :initial_file_path

    def initialize(provider:, default_language:, target_languages:, api_keys: {}, translation_method: :override, initial_file_path: nil)
      @provider = provider.to_sym
      @default_language = default_language
      @target_languages = target_languages
      @api_keys = api_keys
      @translation_method = translation_method.to_sym
      @initial_file_path = initial_file_path
    end
  end
end
