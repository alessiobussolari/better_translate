# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name          = "better_translate"
  spec.version       = BetterTranslate::VERSION
  spec.authors = ['alessio_bussolari']
  spec.email   = ['alessio.bussolari@pandev.it']

  spec.summary       = %q{Gemma per tradurre file YAML in più lingue tramite provider (ChatGPT e Gemini)}
  spec.description   = %q{
BetterTranslate è una gemma che consente di tradurre file YAML partendo da una lingua sorgente verso una o più lingue target.
La gemma supporta differenti provider di traduzione, attualmente ChatGPT (OpenAI) e Google Gemini, e permette di scegliere
la modalità di traduzione: "override" per rigenerare tutte le traduzioni oppure "incremental" per aggiornare solo le chiavi mancanti.

La configurazione della gemma è centralizzata tramite un initializer, dove è possibile definire API key, lingue target, lingua sorgente,
esclusioni di chiavi e la cartella di output. BetterTranslate integra inoltre il monitoraggio del progresso della traduzione tramite una progress bar.
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
