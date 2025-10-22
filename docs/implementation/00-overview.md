# 00 - Overview & Project Structure

[← Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 01 - Setup Dependencies →](./01-setup_dependencies.md)

---

## BetterTranslate - Implementation Plan Overview

This document provides an overview of the complete BetterTranslate implementation based on the detailed specifications.

### Project Goals

BetterTranslate is a powerful Ruby gem designed to automatically translate YAML locale files using AI-powered translation providers. It's optimized for Rails applications but works with any Ruby project.

### Key Features

- **Multiple AI Providers**: ChatGPT (GPT-5-nano), Google Gemini (gemini-2.0-flash-exp), Anthropic Claude (claude-3-5-sonnet-20241022)
- **Smart Translation Strategies**: Automatic selection between Deep (< 50 strings) and Batch (≥ 50 strings) processing
- **Intelligent Caching**: LRU cache with configurable capacity and TTL
- **Rails Integration**: 3 generators (install, translate, analyze)
- **Direct Translation API**: Helper methods for on-demand text translation
- **Thread-Safe**: Mutex-protected cache and rate limiting
- **Comprehensive Testing**: RSpec with VCR for API mocking

---

## Complete File Structure

### Core Library (21 files)

```
lib/better_translate/
├── better_translate.rb              # Main module (UPDATE)
├── version.rb                       # Exists
├── errors.rb                        # NEW - Error hierarchy
├── configuration.rb                 # NEW - Configuration class
├── cache.rb                         # NEW - LRU Cache
├── rate_limiter.rb                  # NEW - Rate limiting
├── validator.rb                     # NEW - Input validation
├── yaml_handler.rb                  # NEW - YAML operations
├── translator.rb                    # NEW - Main translator
├── progress_tracker.rb              # NEW - Progress display
├── provider_factory.rb              # NEW - Provider factory
├── helpers.rb                       # NEW - Direct translation API
├── providers/
│   ├── base_http_provider.rb       # NEW - Base class
│   ├── chatgpt_provider.rb         # NEW - OpenAI
│   ├── gemini_provider.rb          # NEW - Google
│   └── anthropic_provider.rb       # NEW - Anthropic Claude
├── strategies/
│   ├── base_strategy.rb            # NEW - Base strategy
│   ├── deep_strategy.rb            # NEW - Individual translation
│   ├── batch_strategy.rb           # NEW - Batch translation
│   └── strategy_selector.rb       # NEW - Auto-selection
└── utils/
    └── hash_flattener.rb           # NEW - Nested hash utils
```

### Rails Generators (4 files)

```
lib/generators/better_translate/
├── install/
│   ├── install_generator.rb       # NEW
│   └── templates/
│       └── initializer.rb.tt       # NEW
├── translate/
│   └── translate_generator.rb     # NEW
└── analyze/
    └── analyze_generator.rb       # NEW
```

### Test Suite (~21 files)

```
spec/
├── spec_helper.rb                  # UPDATE
├── better_translate_spec.rb        # UPDATE
├── support/
│   ├── vcr.rb                      # NEW - VCR config
│   └── test_helpers.rb             # NEW - TranslationHelper
├── fixtures/
│   ├── en.yml                      # NEW - Test YAML
│   ├── it.yml                      # NEW
│   └── invalid.yml                 # NEW
├── vcr_cassettes/                  # NEW directory
├── better_translate/
│   ├── configuration_spec.rb      # NEW
│   ├── cache_spec.rb              # NEW
│   ├── rate_limiter_spec.rb       # NEW
│   ├── validator_spec.rb          # NEW
│   ├── yaml_handler_spec.rb       # NEW
│   ├── translator_spec.rb         # NEW
│   ├── progress_tracker_spec.rb   # NEW
│   ├── provider_factory_spec.rb   # NEW
│   ├── helpers_spec.rb            # NEW
│   ├── providers/
│   │   ├── base_http_provider_spec.rb  # NEW
│   │   ├── chatgpt_provider_spec.rb    # NEW
│   │   ├── gemini_provider_spec.rb     # NEW
│   │   └── anthropic_provider_spec.rb  # NEW
│   ├── strategies/
│   │   ├── deep_strategy_spec.rb       # NEW
│   │   ├── batch_strategy_spec.rb      # NEW
│   │   └── strategy_selector_spec.rb   # NEW
│   └── utils/
│       └── hash_flattener_spec.rb      # NEW
├── integration/
│   └── translation_workflow_spec.rb    # NEW
└── generators/
    ├── install_generator_spec.rb       # NEW
    ├── translate_generator_spec.rb     # NEW
    └── analyze_generator_spec.rb       # NEW
```

### Documentation & Examples (6 files)

```
Root files:
├── Gemfile                         # UPDATE
├── better_translate.gemspec        # UPDATE
├── .yardopts                       # NEW
├── README.md                       # UPDATE
├── CHANGELOG.md                    # UPDATE
└── examples/
    ├── basic_usage.rb              # NEW
    ├── advanced_usage.rb           # NEW
    └── direct_translation.rb       # NEW
```

**TOTAL: ~53 files**

---

## Implementation Phases

The implementation is divided into 11 phases, each building upon the previous:

| # | Phase | Files | Description |
|---|-------|-------|-------------|
| 01 | [Setup Dependencies](./01-setup_dependencies.md) | 3 | Gemfile, gemspec, .yardopts |
| 02 | [Error Handling](./02-error_handling.md) | 1 | Complete error hierarchy |
| 03 | [Core Components](./03-core_components.md) | 5 | Configuration, Cache, RateLimiter, Validator, HashFlattener |
| 04 | [Provider Architecture](./04-provider_architecture.md) | 5 | BaseHttpProvider + 3 providers + Factory |
| 05 | [Translation Logic](./05-translation_logic.md) | 6 | YAMLHandler, 3 Strategies, ProgressTracker, Translator |
| 06 | [Main Module & API](./06-main_module_api.md) | 1 | Update lib/better_translate.rb |
| 07 | [Direct Translation Helpers](./07-direct_translation_helpers.md) | 1 | Helpers module for on-demand translation |
| 08 | [Rails Integration](./08-rails_integration.md) | 4 | 3 generators + templates |
| 09 | [Testing Suite](./09-testing_suite.md) | ~21 | Complete RSpec test suite |
| 10 | [Documentation & Examples](./10-documentation_examples.md) | 3 | YARD, usage examples |
| 11 | [Quality & Security](./11-quality_security.md) | - | RuboCop, Bundler Audit, CI/CD |

---

## Development Effort Estimate

| Area | Estimated Time |
|------|----------------|
| Core Implementation | 10-12 hours |
| Rails Integration | 2-3 hours |
| Testing Suite | 6-8 hours |
| Documentation | 3-4 hours |
| QA & Fixes | 3-4 hours |
| **TOTAL** | **24-31 hours** |

---

## Recommended Implementation Order

1. ✅ **01 - Setup Dependencies**: Foundation (Gemfile, gemspec, .yardopts)
2. ✅ **02 - Error Handling**: Error hierarchy for all modules
3. ✅ **03 - Core Components**: Configuration, Cache, RateLimiter, Validator, HashFlattener
4. ✅ **04 - Provider Architecture**: BaseHttpProvider, ChatGPT, Gemini, Anthropic, Factory
5. ✅ **05 - Translation Logic**: YAMLHandler, Strategies, ProgressTracker, Translator
6. ✅ **06 - Main Module & API**: Update lib/better_translate.rb
7. ✅ **07 - Direct Translation Helpers**: On-demand text translation
8. ✅ **08 - Rails Integration**: Generators for Rails apps
9. ✅ **09 - Testing Suite**: Complete test coverage
10. ✅ **10 - Documentation & Examples**: YARD + usage examples
11. ✅ **Quality & Security**: Final checks and CI/CD

---

## Important Development Notes

### Mandatory Requirements

1. **YARD Documentation** - All public classes and methods must have comprehensive YARD documentation
2. **Faraday HTTP Client** - All HTTP connections must use Faraday (not Net::HTTP or HTTParty)
3. **Thread Safety** - Cache and RateLimiter must be thread-safe with Mutex
4. **Environment Variables** - All API keys must be read from ENV variables
5. **RuboCop Compliance** - Code must pass RuboCop before commits
6. **Test Coverage** - Minimum 90% coverage for core components
7. **Test-Driven Development** - ALWAYS write tests BEFORE implementation (see CLAUDE.md)

### Code Style

- **String Literals**: Double quotes (enforced by RuboCop)
- **Ruby Version**: 3.0+
- **Frozen String Literals**: Required at top of all files

### Security

- **Never hardcode API keys**
- **VCR anonymization** for test cassettes
- **Input validation** for all user-provided data
- **Bundle audit** for dependency vulnerabilities

---

## Project Information

- **Author**: alessiobussolari
- **Email**: alessio.bussolari@pandev.it
- **License**: MIT
- **Repository**: https://github.com/alessiobussolari/better_translate

---

[← Back to Index](../../IMPLEMENTATION_PLAN.md) | [Next: 01 - Setup Dependencies →](./01-setup_dependencies.md)
