# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name = "better_translate"
  spec.version = BetterTranslate::VERSION
  spec.authors = ["alessiobussolari"]
  spec.email = ["alessio@cosmic.tech"]

  spec.summary       = %q{Gemma per tradurre file YAML utilizzando Google o OpenAI}
  spec.description   = %q{BetterTranslate permette di tradurre file YAML partendo da una lingua target e generando traduzioni in più lingue. È possibile scegliere tra provider Google e OpenAI e definire la modalità di traduzione (override o incremental).}
  spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Eventuali dipendenze
  spec.add_dependency "yaml"
  spec.add_dependency "httparty"  # per eventuali chiamate HTTP
end


# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = "better_translate"
  spec.version       = "0.1.0"
  spec.authors       = ["Tuo Nome"]
  spec.email         = ["tuo@email"]

  spec.summary       = %q{Gemma per tradurre file YAML utilizzando Google o OpenAI}
  spec.description   = %q{BetterTranslate permette di tradurre file YAML partendo da una lingua target e generando traduzioni in più lingue. È possibile scegliere tra provider Google e OpenAI e definire la modalità di traduzione (override o incremental).}
  spec.homepage      = "http://tuosito.it"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  # Eventuali dipendenze
  spec.add_dependency "yaml"
  spec.add_dependency "httparty"  # per eventuali chiamate HTTP
end
