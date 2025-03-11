# frozen_string_literal: true

require_relative "lib/better_translate/version"

Gem::Specification.new do |spec|
  spec.name          = "better_translate"
  spec.version       = BetterTranslate::VERSION
  spec.authors       = ["Alessio Bussolari"]
  spec.email         = ["alessio.bussolari@pandev.it"]

  spec.summary       = "AI-powered YAML translation with ChatGPT and Google Gemini"
  spec.description   = <<~DESC
    BetterTranslate is a powerful Ruby gem for translating YAML files using AI providers.
    
    Key features:
    * Multiple AI providers support (ChatGPT and Google Gemini)
    * Smart translation modes (override/incremental)
    * LRU caching for performance
    * Precise key exclusion control
    * Rails integration with generators
    * Progress tracking with progress bar
    * Comprehensive test coverage
    
    Perfect for internationalizing Ruby/Rails applications with minimal effort.
  DESC

  spec.homepage      = "https://github.com/alessiobussolari/better_translate"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Metadata
  spec.metadata = {
    "allowed_push_host"     => "https://rubygems.org",
    "rubygems_mfa_required" => "true",
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => spec.homepage,
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "documentation_uri"     => spec.homepage,
    "wiki_uri"             => "#{spec.homepage}/wiki"
  }

  # Include files
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == File.basename(__FILE__)) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.|appveyor|Gemfile)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ruby-progressbar", "~> 1.13"  # Progress tracking
  spec.add_dependency "httparty", "~> 0.21.0"       # HTTP client for API calls
  spec.add_dependency "zeitwerk", "~> 2.6"          # Modern code autoloading

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "vcr", "~> 6.1"
end
