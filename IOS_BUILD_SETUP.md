# iOS Build Setup for GitHub Actions

This guide explains how to set up automated iOS builds for your Flutter app using GitHub Actions.

## 📋 Prerequisites

1. **Apple Developer Account** - Required for code signing
2. **GitHub Repository** - Your Flutter project must be on GitHub
3. **iOS App Bundle ID** - Configured in your Flutter project

## 🚀 Quick Start

### 1. Basic iOS Build (No Code Signing)

The basic workflow (`ios-build.yml`) will:
- Build your iOS app without code signing
- Upload build artifacts to GitHub
- Work on every push to main/develop branches

**No additional setup required!** Just push your code and the workflow will run automatically.

### 2. Advanced iOS Build (With Code Signing)

For App Store distribution, you need to set up code signing:

#### Step 1: Generate iOS Certificate and Provisioning Profile

1. **Export your iOS Distribution Certificate:**
   ```bash
   # In Xcode or Keychain Access
   # Export as .p12 file with a password
   ```

2. **Download your Provisioning Profile:**
   - Go to Apple Developer Portal
   - Download the provisioning profile for your app

#### Step 2: Add GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `IOS_P12_BASE64` | Base64 encoded .p12 certificate | `base64 -i certificate.p12` |
| `IOS_P12_PASSWORD` | Password for the .p12 file | `your_password` |
| `APPSTORE_ISSUER_ID` | Apple App Store Connect Issuer ID | `57246b42-0d85-4b8c-9c8c-1234567890ab` |
| `APPSTORE_API_KEY_ID` | App Store Connect API Key ID | `ABC123DEF4` |
| `APPSTORE_API_PRIVATE_KEY` | App Store Connect API Private Key | `-----BEGIN PRIVATE KEY-----...` |

#### Step 3: Update Bundle ID

In `ios/ExportOptions.plist`, replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID.

#### Step 4: Create a Release Tag

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will trigger the release workflow and create a GitHub release with the IPA file.

## 📁 Workflow Files

### `ios-build.yml`
- **Trigger:** Push to main/develop, PRs, manual
- **Purpose:** Basic iOS build without code signing
- **Output:** Build artifacts for testing

### `ios-release.yml`
- **Trigger:** Git tags (v*), manual
- **Purpose:** Production iOS build with code signing
- **Output:** Signed IPA file and GitHub release

## 🔧 Configuration

### Update Bundle ID
In `ios/Runner.xcodeproj/project.pbxproj`, update:
```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.crmApp;
```

### Update Team ID
In `ios/ExportOptions.plist`, update:
```xml
<key>teamID</key>
<string>YOUR_ACTUAL_TEAM_ID</string>
```

## 📱 Build Artifacts

### Basic Build
- **Location:** `build/ios/iphoneos/`
- **Files:** App bundle without code signing
- **Use:** Testing on simulator or development devices

### Release Build
- **Location:** `build/ios/ipa/`
- **Files:** Signed IPA file ready for App Store
- **Use:** App Store distribution

## 🛠️ Troubleshooting

### Common Issues

1. **Pod Install Fails**
   ```bash
   # In the workflow, try:
   cd ios
   pod install --repo-update
   cd ..
   ```

2. **Code Signing Issues**
   - Verify all secrets are correctly set
   - Check that certificate and provisioning profile match
   - Ensure bundle ID matches in all places

3. **Build Fails**
   - Check Flutter version compatibility
   - Verify all dependencies are compatible
   - Review build logs for specific errors

### Manual Testing

To test locally (requires macOS):
```bash
flutter build ios --release --no-codesign
```

## 📊 Monitoring

- **Workflow Status:** Check Actions tab in GitHub
- **Build Logs:** Available in the workflow run details
- **Artifacts:** Download from the workflow run page

## 🔄 Automation

The workflows will automatically:
- ✅ Build on every push to main/develop
- ✅ Create releases on version tags
- ✅ Upload artifacts for download
- ✅ Create GitHub releases with IPA files

## 📞 Support

If you encounter issues:
1. Check the workflow logs in GitHub Actions
2. Verify all secrets are correctly configured
3. Ensure your Apple Developer account has the necessary certificates
4. Review the Flutter iOS build documentation

---

**Note:** The basic workflow (`ios-build.yml`) will work immediately without any additional setup. The advanced workflow (`ios-release.yml`) requires Apple Developer account configuration. 