# Sparkle Setup Guide

This guide explains how to set up Sparkle for automatic updates in ClaudeCodeMonitor.

## Prerequisites

- macOS with Homebrew installed
- Access to the GitHub repository secrets

## Initial Setup (One-time only)

### 1. Install Sparkle Tools

```bash
# Download Sparkle
curl -L -o sparkle.tar.xz https://github.com/sparkle-project/Sparkle/releases/download/2.5.2/Sparkle-2.5.2.tar.xz
tar -xf sparkle.tar.xz

# The tools will be in Sparkle.framework/Versions/Current/Resources/
```

### 2. Generate EdDSA Key Pair

```bash
# Navigate to Sparkle tools directory
cd Sparkle.framework/Versions/Current/Resources/

# Generate key pair
./generate_keys

# This will output:
# - Public key (EdDSA)
# - Private key (EdDSA)
```

### 3. Configure Public Key

1. Copy the public key from the output
2. Update `Info.plist`:
   ```xml
   <key>SUPublicEDKey</key>
   <string>YOUR_PUBLIC_KEY_HERE</string>
   ```
3. Commit and push this change

### 4. Configure Private Key

1. Go to GitHub repository settings
2. Navigate to Settings → Secrets and variables → Actions
3. Create a new repository secret named `SPARKLE_PRIVATE_KEY`
4. Paste the private key (including the entire line)

## How It Works

### Release Process

When a PR is merged to main:

1. The release workflow creates a new version
2. Builds and signs the app
3. Creates a DMG file
4. If `SPARKLE_PRIVATE_KEY` is set:
   - Generates EdDSA signature for the DMG
   - Creates `appcast.xml` with update information
   - Uploads both DMG and appcast.xml to GitHub Release

### Update Check

1. ClaudeCodeMonitor checks the appcast.xml URL periodically
2. If a new version is found, it verifies the EdDSA signature
3. Prompts user to download and install the update

### appcast.xml Location

The appcast.xml file is available at:
```
https://github.com/K9i-0/ClaudeCodeMonitor/releases/latest/download/appcast.xml
```

## Security Notes

- **Never commit the private key** to the repository
- The private key should only be stored in GitHub Secrets
- The public key is safe to commit and share
- EdDSA signatures ensure updates haven't been tampered with

## Testing Updates

To test the update mechanism:

1. Build a test version with a lower version number
2. Run the app
3. Check for updates from Settings → Update Settings
4. Verify that the app detects the newer version

## Troubleshooting

### "No updates available" when there should be

1. Check that `SUFeedURL` in Info.plist is correct
2. Verify appcast.xml exists at the URL
3. Check Console.app for Sparkle-related errors

### Signature verification failed

1. Ensure the public key in Info.plist matches the one used to generate signatures
2. Verify the private key in GitHub Secrets is correct
3. Check that the DMG hasn't been modified after signing

## Manual Key Generation (Alternative)

If you need to generate keys manually:

```bash
# Generate private key
openssl genpkey -algorithm ed25519 -out private_key.pem

# Extract public key
openssl pkey -in private_key.pem -pubout -out public_key.pem

# Convert to Sparkle format (base64)
cat private_key.pem | openssl base64 -A
cat public_key.pem | openssl base64 -A
```

Note: Use the Sparkle-provided `generate_keys` tool for best compatibility.