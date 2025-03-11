# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name          = "better_translate"
  spec.version       = BetterTranslate::VERSION
  spec.authors = ['alessio_bussolari']
  spec.email   = ['alessio.bussolari@pandev.it']

  spec.summary       = %q{Gem for translating YAML files into multiple languages using providers (ChatGPT and Gemini)}
  spec.description   = %q{
BetterTranslate is a gem that allows you to translate YAML files from a source language into one or more target languages.
The gem supports different translation providers, currently ChatGPT (OpenAI) and Google Gemini, and allows you to choose
the translation mode: "override" to regenerate all translations or "incremental" to update only the missing keys.

The gem's configuration is centralized via an initializer, where you can define API keys, target languages, source language,
key exclusions, and the output folder. BetterTranslate also integrates translation progress tracking using a progress bar.
  }

  spec.homepage      = "https://github.com/alessiobussolari/better_translate"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"]   = "https://rubygems.org"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata["homepage_uri"]        = spec.homepage
  spec.metadata["source_code_uri"]     = "https://github.com/alessiobussolari/better_translate"
  spec.metadata["changelog_uri"]       = "https://github.com/alessiobussolari/better_translate/blob/main/CHANGELOG.md"

  # Specifica quali file devono essere inclusi nella gemma.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE.txt']
  spec.require_paths = ["lib"]

  # Dipendenze a runtime
  spec.add_dependency "yaml"
  spec.add_dependency "httparty"            # per eventuali chiamate HTTP
  spec.add_dependency "ruby-progressbar", "~> 1.11"   # per visualizzare la progress bar durante la traduzione

  # Dipendenze per lo sviluppo
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
