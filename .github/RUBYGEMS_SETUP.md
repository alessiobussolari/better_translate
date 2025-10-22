# RubyGems Trusted Publishing Setup

This guide explains how to configure RubyGems Trusted Publishing for automatic gem releases via GitHub Actions.

## What is Trusted Publishing?

Trusted Publishing uses GitHub's OIDC identity provider to authenticate GitHub Actions workflows with RubyGems.org, eliminating the need for API keys.

**Benefits**:
- ✅ **No API keys to manage** - More secure
- ✅ **Automatic authentication** - Works seamlessly with GitHub Actions
- ✅ **Official method** - Recommended by RubyGems team
- ✅ **Free** - No additional cost

## Setup Instructions

### Step 1: Publish Your First Version Manually

Before setting up trusted publishing, you need to publish at least one version of your gem manually:

```bash
# Build the gem
bundle exec rake build

# Publish to RubyGems (requires account)
gem push pkg/better_translate-1.0.0.gem
```

**Note**: You'll need a RubyGems account. Create one at https://rubygems.org/sign_up if you don't have one.

### Step 2: Configure Trusted Publishing on RubyGems.org

1. **Go to your gem page**: https://rubygems.org/gems/better_translate

2. **Navigate to Settings**:
   - Click on "Edit" or your gem's settings page
   - Or go directly to: https://rubygems.org/gems/better_translate/trusted_publishers

3. **Add Trusted Publisher**:
   - Click "Add Trusted Publisher"
   - Fill in the form:
     - **Repository owner**: `alessiobussolari`
     - **Repository name**: `better_translate`
     - **Workflow filename**: `release.yml`
     - **Environment name**: (leave empty or use `rubygems`)

4. **Save** the configuration

### Step 3: Verify GitHub Actions Workflow

The workflow is already configured in `.github/workflows/release.yml` with:

```yaml
permissions:
  contents: write
  id-token: write  # Required for trusted publishing
```

### Step 4: Test the Workflow

1. **Update version** in `lib/better_translate/version.rb`:
   ```ruby
   VERSION = "1.0.1"
   ```

2. **Commit and tag**:
   ```bash
   git add -A
   git commit -m "chore: Bump version to 1.0.1"
   git push origin main

   git tag v1.0.1
   git push origin v1.0.1
   ```

3. **Watch GitHub Actions**:
   - Go to https://github.com/alessiobussolari/better_translate/actions
   - The "Release Gem to RubyGems" workflow should run automatically
   - It will:
     - ✅ Run tests
     - ✅ Run RuboCop
     - ✅ Build the gem
     - ✅ Publish to RubyGems.org
     - ✅ Create GitHub Release

4. **Verify on RubyGems**:
   - Check https://rubygems.org/gems/better_translate
   - New version should appear within minutes

## Troubleshooting

### "Trusted publisher not configured" Error

**Problem**: GitHub Actions fails with error about trusted publishing.

**Solution**:
1. Ensure you've completed Step 2 above
2. Verify the repository name and workflow filename match exactly
3. Wait a few minutes for RubyGems.org to sync

### "Permission denied" Error

**Problem**: Workflow doesn't have permission to publish.

**Solution**:
1. Check that `id-token: write` permission is set in workflow
2. Verify GitHub Actions is enabled for your repository
3. Check repository settings → Actions → General → Workflow permissions

### First Manual Publish Fails

**Problem**: Can't push gem manually for first time.

**Solution**:
1. Ensure you're logged into RubyGems: `gem signin`
2. Enter your RubyGems credentials
3. Try push again: `gem push pkg/better_translate-1.0.0.gem`

## Alternative: Using API Token

If you prefer not to use trusted publishing, you can use an API token:

1. **Generate API token**:
   - Go to https://rubygems.org/profile/api_keys
   - Click "New API Key"
   - Name: "GitHub Actions"
   - Scopes: "Push rubygems" only
   - Copy the token

2. **Add to GitHub Secrets**:
   - Go to https://github.com/alessiobussolari/better_translate/settings/secrets/actions
   - Click "New repository secret"
   - Name: `RUBYGEMS_API_KEY`
   - Value: (paste your token)

3. **Update workflow** (`.github/workflows/release.yml`):
   ```yaml
   - name: Publish to RubyGems
     env:
       GEM_HOST_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }}
     run: |
       bundle exec rake build
       gem push pkg/*.gem
   ```

## Release Workflow

Once setup is complete, your release workflow is:

```bash
# 1. Update version
vim lib/better_translate/version.rb

# 2. Update CHANGELOG
vim CHANGELOG.md

# 3. Commit
git add -A
git commit -m "chore: Release v1.0.1"

# 4. Tag and push
git tag v1.0.1
git push origin main
git push origin v1.0.1

# 5. GitHub Actions does the rest automatically! 🎉
```

Within 2-3 minutes:
- ✅ Tests run on GitHub Actions
- ✅ Gem published to RubyGems.org
- ✅ GitHub Release created
- ✅ Users can `gem install better_translate`

## Resources

- [RubyGems Trusted Publishing Guide](https://guides.rubygems.org/trusted-publishing/)
- [rubygems/release-gem Action](https://github.com/rubygems/release-gem)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
