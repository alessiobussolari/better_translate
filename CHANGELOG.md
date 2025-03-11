# Changelog

All notable changes to BetterTranslate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2025-03-11

### Added
- Comprehensive RSpec test suite covering:
  - Core translation functionality
  - LRU cache implementation
  - Provider selection and initialization
  - Error handling
  - Configuration management
- Improved documentation with badges and testing information

### Changed
- Made `translate` method public in `Service` class for better testability
- Reorganized README.md with better structure and modern layout

## [0.3.0] - 2025-03-11

### Added
- New translation helper methods:
  - `translate_text_to_languages`: Translate single text to multiple languages
  - `translate_texts_to_languages`: Translate multiple texts to multiple languages
- LRU caching for improved performance

### Changed
- Enhanced error handling in translation providers
- Improved method documentation

## [0.2.0] - 2025-03-11

### Added
- Two-step filtering process:
  - Global exclusions using `global_exclusions`
  - Language-specific exclusions using `exclusions_per_language`

### Changed
- Improved filtering logic to handle language-specific exclusions independently
- Enhanced documentation for exclusion configuration

### Fixed
- Issue with language-specific exclusions affecting global filtering

## [0.1.1] - 2025-03-10

### Added
- New Rails generator: `rails generate better_translate:translate`
  - Triggers translation process
  - Displays progress messages
  - Integrates with existing configuration

## [0.1.0] - 2025-03-10

### Added
- Initial release with core features:
  - YAML file translation from source to multiple target languages
  - Multiple provider support (ChatGPT and Google Gemini)
  - Progress tracking with ruby-progressbar
  - Centralized configuration via initializer
  - Two translation modes: override and incremental
  - Key exclusion system
  - Rails integration

### Configuration
- API key management for providers
- Source and target language settings
- Output folder configuration
- Translation mode selection
- Exclusion patterns support
