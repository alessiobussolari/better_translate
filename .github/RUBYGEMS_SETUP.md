# RubyGems Publishing Setup

This guide explains how to configure automatic gem releases to RubyGems.org via GitHub Actions using an API token.

## What You'll Need

- A RubyGems.org account
- A GitHub repository with push access
- 5 minutes to set up

**Benefits**:
- ✅ **Automatic publishing** - On GitHub release creation
- ✅ **Works with MFA** - Token bypasses 2FA requirement
- ✅ **Secure** - Token stored in GitHub Secrets (encrypted)
- ✅ **Minimal permissions** - Token only has "push" scope

## Setup Instructions

### Step 1: Create RubyGems API Token

1. **Go to RubyGems API Keys page**: https://rubygems.org/profile/api_keys

2. **Click "New API Key"**

3. **Configure the token**:
   - **Name**: `GitHub Actions - better_translate`
   - **Scopes**: Check **only** "Push rubygems"
   - **Index rubygems**: ✅ Check this if you want the token to work for all your gems
   - **MFA**: The token will bypass MFA for automated operations

4. **Click "Create"**

5. **Copy the token immediately** - You'll only see it once!
   - It will look like: `rubygems_xxxxxxxxxxxx`

### Step 2: Add Token to GitHub Secrets

1. **Go to your repository secrets**: https://github.com/alessiobussolari/better_translate/settings/secrets/actions

2. **Click "New repository secret"**

3. **Configure the secret**:
   - **Name**: `RUBYGEMS_API_KEY` (must match exactly!)
   - **Secret**: (paste the token you copied from RubyGems)

4. **Click "Add secret"**

### Step 3: Publish First Version Manually

Before the automated workflow can work, you need to create the gem on RubyGems:

```bash
# Build the gem
bundle exec rake build

# Publish to RubyGems
# This will prompt for OTP if you have MFA enabled
gem push pkg/better_translate-1.0.0.gem
```

**Note**: After this first manual push, all future versions will be published automatically via GitHub Actions!

### Step 4: Test the Workflow

1. **Update version** in `lib/better_translate/version.rb`:
   ```ruby
   VERSION = "1.0.1"
   ```

2. **Commit and push**:
   ```bash
   git add -A
   git commit -m "chore: Bump version to 1.0.1"
   git push origin main
   ```

3. **Create a GitHub Release**:
   - Go to: https://github.com/alessiobussolari/better_translate/releases/new
   - **Tag**: `v1.0.1` (create new tag)
   - **Title**: `v1.0.1 - Your release title`
   - **Description**: Add release notes
   - Click **"Publish release"**

4. **Watch GitHub Actions**:
   - Go to https://github.com/alessiobussolari/better_translate/actions
   - The "Publish Gem to RubyGems" workflow will run automatically
   - It will:
     - ✅ Run unit tests
     - ✅ Run RuboCop
     - ✅ Build the gem
     - ✅ Publish to RubyGems.org (using your API token)
     - ✅ Attach gem file to GitHub release

5. **Verify on RubyGems**:
   - Check https://rubygems.org/gems/better_translate
   - New version should appear within 2-3 minutes

## Troubleshooting

### "Invalid API key" Error

**Problem**: GitHub Actions fails with "Invalid credentials" or "Unauthorized" error.

**Solution**:
1. Verify you've created the RubyGems API token (Step 1)
2. Check the token is added to GitHub Secrets as `RUBYGEMS_API_KEY` (Step 2)
3. Ensure the secret name matches exactly in the workflow file
4. Try regenerating the API token on RubyGems.org

### "Gem not found" Error

**Problem**: GitHub Actions can't find the gem file to push.

**Solution**:
1. Check the gem builds successfully: `bundle exec rake build`
2. Verify `*.gem` file is created in the repository root
3. Ensure the gemspec file name matches: `better_translate.gemspec`

### "Permission denied" Error

**Problem**: Workflow doesn't have permission to attach gem to release.

**Solution**:
1. Verify GitHub Actions is enabled for your repository
2. Check repository settings → Actions → General → Workflow permissions
3. Ensure "Read and write permissions" is selected

### First Manual Publish Fails

**Problem**: Can't push gem manually for first time.

**Solution**:
1. Ensure you're logged into RubyGems: `gem signin`
2. Enter your RubyGems credentials
3. Try push again: `gem push pkg/better_translate-1.0.0.gem`

## Release Workflow

Once setup is complete, your release workflow is:

```bash
# 1. Update version
vim lib/better_translate/version.rb  # VERSION = "1.0.1"

# 2. Update CHANGELOG
vim CHANGELOG.md

# 3. Commit and push
git add -A
git commit -m "chore: Release v1.0.1"
git push origin main

# 4. Create GitHub Release (via web or CLI)
# Option A - Web:
# Go to: https://github.com/alessiobussolari/better_translate/releases/new
# Tag: v1.0.1, Title: v1.0.1, Description: release notes
# Click "Publish release"

# Option B - CLI (if gh is installed):
gh release create v1.0.1 \
  --title "v1.0.1" \
  --notes "See CHANGELOG.md for details"

# 5. GitHub Actions does the rest automatically! 🎉
```

Within 2-3 minutes:
- ✅ Tests run on GitHub Actions
- ✅ Gem published to RubyGems.org
- ✅ Gem file attached to GitHub Release
- ✅ Users can `gem install better_translate`

## Resources

- [RubyGems Trusted Publishing Guide](https://guides.rubygems.org/trusted-publishing/)
- [rubygems/release-gem Action](https://github.com/rubygems/release-gem)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
