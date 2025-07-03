# Homebrew Cask Submission Guide for ClaudeCodeMonitor

This guide provides step-by-step instructions for submitting ClaudeCodeMonitor (ccmonitor) to Homebrew Cask.

## Pre-submission Checklist

Before starting the submission process, ensure you have:

- [ ] A stable release with a versioned DMG file
- [ ] The DMG is hosted on a reliable, permanent URL (GitHub Releases recommended)
- [ ] SHA256 checksum of the DMG file
- [ ] The app is properly code-signed (ad-hoc signing is acceptable)
- [ ] The app has been tested on a clean macOS installation
- [ ] Homebrew is installed and up to date: `brew update`
- [ ] You have a GitHub account
- [ ] The app follows macOS naming conventions (e.g., `ClaudeCodeMonitor.app`)

## Step 1: Calculate SHA256 Checksum

```bash
# Calculate the SHA256 of your DMG file
shasum -a 256 ClaudeCodeMonitor-v1.0.0.dmg
# Example output: abc123def456... ClaudeCodeMonitor-v1.0.0.dmg
```

## Step 2: Fork and Clone Homebrew Cask

```bash
# Fork the homebrew-cask repository on GitHub (via web interface)
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/homebrew-cask.git
cd homebrew-cask

# Add the upstream remote
git remote add upstream https://github.com/Homebrew/homebrew-cask.git

# Create a new branch for your cask
git checkout -b claude-code-monitor
```

## Step 3: Create the Cask File

Create a new file at `Casks/c/claude-code-monitor.rb`:

```ruby
cask "claude-code-monitor" do
  version "1.0.0"
  sha256 "YOUR_SHA256_CHECKSUM_HERE"

  url "https://github.com/K9i-0/claude-code-monitor/releases/download/v#{version}/ClaudeCodeMonitor-v#{version}.dmg"
  name "ClaudeCodeMonitor"
  desc "Monitor Claude Code API usage and costs from your menubar"
  homepage "https://github.com/K9i-0/claude-code-monitor"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "ClaudeCodeMonitor.app"

  zap trash: [
    "~/Library/Preferences/com.k9i.ClaudeCodeMonitor.plist",
    "~/Library/Application Support/ClaudeCodeMonitor",
  ]
end
```

## Step 4: Validate Your Cask

```bash
# Install your cask locally to test it
brew install --cask ./Casks/c/claude-code-monitor.rb

# Run audit to check for common issues
brew audit --new-cask claude-code-monitor

# Run style checks
brew style --fix Casks/c/claude-code-monitor.rb

# Test the installation
brew reinstall --cask claude-code-monitor

# Test uninstallation
brew uninstall --cask claude-code-monitor

# Test zap (complete removal including preferences)
brew uninstall --zap --cask claude-code-monitor
```

## Step 5: Common Issues and Fixes

### Issue: Audit fails with "url unversioned"
**Fix:** Ensure your URL contains the `#{version}` interpolation

### Issue: "No checksum defined"
**Fix:** Add the `sha256` line with the correct checksum

### Issue: "Cask name doesn't match file name"
**Fix:** Ensure the cask name in the file matches the filename (without .rb)

### Issue: "Homepage SSL verification failed"
**Fix:** Ensure your homepage uses HTTPS with a valid certificate

### Issue: "App sandbox validation failed"
**Fix:** This is just a warning for sandboxed apps - it's acceptable

### Issue: "Code signing verification failed"
**Fix:** Ad-hoc signing is acceptable, but ensure the app is signed:
```bash
codesign -dv --verbose=4 /Applications/ClaudeCodeMonitor.app
```

## Step 6: Commit Your Changes

```bash
# Add your cask file
git add Casks/c/claude-code-monitor.rb

# Commit with a descriptive message
git commit -m "Add ClaudeCodeMonitor 1.0.0"

# Push to your fork
git push origin claude-code-monitor
```

## Step 7: Create Pull Request

### PR Title
```
Add ClaudeCodeMonitor 1.0.0
```

### PR Template
```markdown
### Pre-submission checklist
- [x] The cask was submitted via a pull request to the correct repo (homebrew-cask)
- [x] I've checked the cask doesn't already exist with `brew search claude-code-monitor`
- [x] I've run `brew audit --new-cask claude-code-monitor` and addressed any issues
- [x] I've run `brew style --fix Casks/c/claude-code-monitor.rb` and fixed any style issues
- [x] I've checked the cask installs and uninstalls successfully
- [x] The app is stable and reproducible (not a beta or nightly build)

### Description
ClaudeCodeMonitor is a macOS menubar application that monitors Claude Code API usage and costs in real-time.

### Additional Information
- The app uses ad-hoc code signing, which is acceptable for Homebrew Cask
- Requires Node.js runtime for the ccusage CLI tool integration
- App runs as menubar-only (LSUIElement)
- Supports macOS 13.0 (Ventura) and later

### Release URL
https://github.com/K9i-0/claude-code-monitor/releases/tag/v1.0.0
```

## Step 8: Respond to Feedback

After submitting the PR:

1. **Monitor CI checks** - Fix any failing tests
2. **Respond to reviewer comments** - Usually within 24-48 hours
3. **Make requested changes** - Push additional commits to your branch
4. **Be patient** - Review process can take a few days to a week

## Post-Submission Maintenance

Once accepted:

### Updating the Cask for New Releases

```bash
# Update your fork
git checkout master
git pull upstream master
git push origin master

# Create a new branch
git checkout -b update-claude-code-monitor-1.1.0

# Edit the cask file with new version and SHA256
# Then commit and create a new PR
```

### Testing Updates
```bash
# Test version updates work correctly
brew livecheck claude-code-monitor
```

## Troubleshooting Tips

1. **Always test on a clean macOS VM if possible**
2. **Check existing casks for similar apps as examples**
3. **Join Homebrew's Discourse forum for help**
4. **Review recent merged PRs for current best practices**

## Useful Commands Reference

```bash
# Check if cask already exists
brew search claude-code-monitor

# View cask info
brew info --cask claude-code-monitor

# Check for updates
brew livecheck claude-code-monitor

# View installed casks
brew list --cask

# Check cask dependencies
brew deps claude-code-monitor
```

## Resources

- [Homebrew Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)
- [Homebrew Discourse](https://discourse.brew.sh/)
- [Example PR for menubar app](https://github.com/Homebrew/homebrew-cask/pull/140000)

---

Remember: The Homebrew maintainers are volunteers. Be respectful, patient, and appreciative of their time and effort in reviewing your submission.