# Contributing to BetterTranslate

First off, thank you for considering contributing to BetterTranslate! 🎉

It's people like you that make BetterTranslate such a great tool. We welcome contributions from everyone, whether you're fixing a typo or implementing a major feature.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Code Style](#code-style)
- [Commit Messages](#commit-messages)
- [Pull Requests](#pull-requests)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- Ruby >= 3.0.0
- Bundler
- Git

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/better_translate.git
   cd better_translate
   ```

3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/alessiobussolari/better_translate.git
   ```

### Install Dependencies

```bash
bundle install
```

### Set Up Environment

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Add your API keys (optional, only needed for integration tests):
   ```env
   OPENAI_API_KEY=sk-...
   GEMINI_API_KEY=...
   ANTHROPIC_API_KEY=sk-ant-...
   ```

## Development Workflow

### 1. Create a Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Write clean, readable code
- Follow the existing code style
- Add tests for new features
- Update documentation as needed

### 3. Run Tests

Before committing, make sure all tests pass:

```bash
# Run all tests
bundle exec rake

# Or run individual checks:
bundle exec rake spec          # Tests
bundle exec rake rubocop       # Linting
bundle exec rake steep         # Type checking
bundle exec rake brakeman      # Security scan
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: Add awesome feature"
```

See [Commit Messages](#commit-messages) for guidelines.

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Testing

### Test Structure

- **Unit Tests**: `spec/better_translate/`
  - Fast, no API calls
  - Use WebMock for HTTP stubs

- **Integration Tests**: `spec/integration/`
  - Real API interactions via VCR
  - Require API keys for first run
  - Subsequent runs use recorded cassettes

### Running Tests

```bash
# All tests
bundle exec rspec

# Only unit tests (fast)
bundle exec rspec spec/better_translate/

# Only integration tests
bundle exec rspec spec/integration/ --tag integration

# Specific file
bundle exec rspec spec/better_translate/translator_spec.rb

# Specific line
bundle exec rspec spec/better_translate/translator_spec.rb:42
```

### Writing Tests

**We follow Test-Driven Development (TDD)**:

1. **RED**: Write a failing test
2. **GREEN**: Write minimum code to pass
3. **REFACTOR**: Clean up code

Example:

```ruby
RSpec.describe MyNewFeature do
  describe "#awesome_method" do
    it "does something awesome" do
      feature = MyNewFeature.new
      result = feature.awesome_method

      expect(result).to eq("awesome")
    end
  end
end
```

### Test Coverage

We maintain **93%+ test coverage**. New code should include tests:

```bash
# Check coverage
bundle exec rspec
# View coverage report: open coverage/index.html
```

## Code Style

### RuboCop

We use RuboCop for code style enforcement:

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Key Guidelines

- Use double quotes for strings
- 2 spaces for indentation (no tabs)
- Maximum line length: 120 characters
- Frozen string literals at top of files: `# frozen_string_literal: true`
- YARD documentation for public methods

### YARD Documentation

All public methods must have YARD documentation:

```ruby
# Translates text to target language
#
# @param text [String] The text to translate
# @param lang [String] Target language code (e.g., "it", "fr")
# @return [String] Translated text
# @raise [ValidationError] If input is invalid
#
# @example
#   translate("Hello", "it") #=> "Ciao"
#
def translate(text, lang)
  # ...
end
```

### Type Checking

We use Steep for static type checking:

```bash
# Run type checker
bundle exec steep check

# Check specific file
bundle exec steep check lib/better_translate/translator.rb
```

Type signatures go in `sig/` directory (RBS format).

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
# Good commits
git commit -m "feat: Add support for JSON locale files"
git commit -m "fix: Handle nil values in translations"
git commit -m "docs: Update README with new examples"
git commit -m "test: Add coverage for edge cases"

# With scope
git commit -m "feat(cli): Add --dry-run flag"
git commit -m "fix(cache): Fix TTL expiration bug"
```

### Multi-line Commits

For complex changes:

```
feat: Add parallel translation support

- Implement thread-based concurrent execution
- Add max_concurrent_requests configuration
- Include progress tracking for parallel operations

Closes #42
```

## Pull Requests

### Before Submitting

- [ ] Tests pass: `bundle exec rake`
- [ ] Code follows style guide
- [ ] YARD documentation added for public methods
- [ ] CHANGELOG.md updated (for notable changes)
- [ ] README.md updated (if needed)

### PR Title

Use conventional commit format:

```
feat: Add awesome feature
fix: Resolve critical bug
docs: Improve installation guide
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How has this been tested?

## Checklist
- [ ] Tests pass locally
- [ ] Tests added for new features
- [ ] Documentation updated
- [ ] No RuboCop offenses
- [ ] No Brakeman warnings
```

### Review Process

1. Automated checks run (CI/CD)
2. Maintainer reviews code
3. Address feedback if needed
4. Maintainer merges PR

## Reporting Bugs

### Before Submitting

- Check existing issues
- Try latest version
- Gather reproduction steps

### Bug Report Template

```markdown
**Describe the bug**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. ...
2. ...
3. ...

**Expected behavior**
What you expected to happen

**Actual behavior**
What actually happened

**Environment**
- Ruby version: [e.g., 3.3.4]
- BetterTranslate version: [e.g., 1.1.0]
- OS: [e.g., macOS, Ubuntu]

**Additional context**
Any other relevant information
```

## Suggesting Features

We love feature suggestions! Open an issue with:

```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you've thought about

**Additional Context**
Screenshots, mockups, examples, etc.
```

## Development Commands

```bash
# Run all checks
bundle exec rake

# Individual checks
bundle exec rake spec          # Tests (541 examples)
bundle exec rake rubocop       # Linting
bundle exec rake steep         # Type checking
bundle exec rake brakeman      # Security scan

# Code quality
bundle exec rubocop -a         # Auto-fix style issues
bundle exec yard doc           # Generate documentation
bundle exec bundler-audit      # Check dependencies

# Interactive console
bin/console

# Demo app
ruby spec/dummy/demo_translation.rb
```

## Questions?

Feel free to:
- Open an issue
- Start a discussion
- Email: alessio.bussolari@pandev.it

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to BetterTranslate! 🚀
