# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name = "better_translate"
  spec.version = BetterTranslate::VERSION
  spec.authors = ["alessiobussolari"]
  spec.email = ["alessio.bussolari@pandev.it"]

  spec.summary = "AI-powered YAML locale file translator for Rails and Ruby projects"
  spec.description = "Automatically translate YAML locale files using AI providers (ChatGPT, Gemini, Claude). Features intelligent caching, batch processing, and Rails integration."
  spec.homepage = "https://github.com/alessiobussolari/better_translate"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alessiobussolari/better_translate"
  spec.metadata["changelog_uri"] = "https://github.com/alessiobussolari/better_translate/blob/main/CHANGELOG.md"

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

  # Runtime dependencies
  spec.add_dependency "csv", "~> 3.0"
  spec.add_dependency "faraday", "~> 2.0"
end
