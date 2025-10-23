# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Measures

BetterTranslate implements multiple security measures to protect your data and application:

### 🔒 Static Security Analysis
- **Brakeman**: Automated security scanner running on every commit
- Checks for 76+ security vulnerabilities including:
  - SQL Injection
  - Cross-Site Scripting (XSS)
  - Command Injection
  - File Access vulnerabilities
  - Unsafe Deserialization
  - Mass Assignment issues

### 🛡️ Dependency Security
- **Bundler Audit**: Regular checks for vulnerable dependencies
- Automated dependency updates via Dependabot (if configured)
- Minimal runtime dependencies (only Faraday)

### 🔐 API Key Protection
- API keys are never logged or stored in code
- VCR cassettes automatically anonymize API keys
- `.env` files are git-ignored by default
- Comprehensive validation prevents key exposure

### ✅ Code Quality
- **RuboCop**: Style and security linting
- **Steep**: Static type checking
- 93%+ test coverage with comprehensive test suite
- Type-safe configuration with validation

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

### 🚨 **DO NOT** disclose the vulnerability publicly

Please report security vulnerabilities privately to protect users.

### 📧 How to Report

**Email**: alessio.bussolari@pandev.it

**Subject**: `[SECURITY] BetterTranslate Vulnerability Report`

**Include in your report**:
1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** and attack scenarios
4. **Suggested fix** (if you have one)
5. **Your contact information** for follow-up

### ⏱️ Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depending on severity
  - Critical: 24-48 hours
  - High: 7 days
  - Medium: 30 days
  - Low: 90 days

### 🎁 Recognition

We appreciate security researchers who responsibly disclose vulnerabilities:

- Your name will be credited in our CHANGELOG (unless you prefer to remain anonymous)
- We may offer a "Hall of Fame" mention in this file
- Significant findings may be eligible for acknowledgment in release notes

## Security Best Practices

When using BetterTranslate:

### ✅ Recommended Practices

1. **API Keys**:
   - Store API keys in environment variables
   - Use `.env` files (never commit them)
   - Rotate keys regularly
   - Use separate keys for dev/staging/production

2. **Configuration**:
   - Validate all configuration before use
   - Use `config.validate!` explicitly
   - Review exclusion lists for sensitive data
   - Enable dry_run mode for testing

3. **File Permissions**:
   - Restrict access to locale files
   - Review backup files (`.bak`) security
   - Use appropriate file permissions (644 for files, 755 for directories)

4. **Dependencies**:
   - Run `bundle audit` regularly
   - Keep gems updated
   - Review CHANGELOG for security updates

### ❌ Avoid These Mistakes

1. **DO NOT** hardcode API keys in source code
2. **DO NOT** commit `.env` files to version control
3. **DO NOT** expose translation API keys in client-side code
4. **DO NOT** disable SSL verification in production
5. **DO NOT** ignore Brakeman or RuboCop security warnings

## Security Scanning

### Run Security Checks Locally

```bash
# Run Brakeman security scanner
bundle exec rake brakeman

# Check for vulnerable dependencies
bundle exec bundler-audit check --update

# Run full test suite with security checks
bundle exec rake  # includes spec, rubocop, steep, brakeman
```

### Continuous Integration

Our CI pipeline automatically runs:
- Brakeman security scanner
- RuboCop with security cops
- Steep type checking
- Comprehensive test suite (541 tests)
- Code coverage analysis (93%+)

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby Security](https://ruby-lang.org/en/security/)
- [Brakeman Documentation](https://brakemanscanner.org/docs/)
- [Bundler Audit](https://github.com/rubysec/bundler-audit)

## Security Hall of Fame

Thank you to these security researchers who helped improve BetterTranslate:

<!-- Future contributors will be listed here -->
_No vulnerabilities reported yet._

---

**Last Updated**: 2025-10-23
**Contact**: alessio.bussolari@pandev.it
