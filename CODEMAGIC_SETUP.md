# 🚀 Codemagic CI/CD Setup for Flutter CRM App

This guide will help you set up Codemagic CI/CD for building macOS and iOS apps.

## 📋 Prerequisites

- Codemagic account (https://codemagic.io)
- Apple Developer account (for iOS/macOS builds)
- Google Play Console account (for Android builds)

## 🎯 Quick Setup

### **Step 1: Connect Your Repository**

1. **Go to Codemagic**: https://codemagic.io
2. **Sign in** with your GitHub account
3. **Add your repository**: `aaryesha17/AluminumFormworkCRM`
4. **Select the repository** and click "Set up build"

### **Step 2: Configure Build Settings**

1. **Select workflow**: Choose `ios-workflow` or `macos-workflow`
2. **Configure environment variables**:
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`

### **Step 3: Set Up Code Signing**

#### **For iOS:**
1. **Apple Developer Account**: Ensure you have proper certificates
2. **App Store Connect**: Set up your app in App Store Connect
3. **Provisioning Profiles**: Codemagic will handle this automatically

#### **For macOS:**
1. **Developer ID**: For distribution outside App Store
2. **App Store**: For Mac App Store distribution

## 🔧 Configuration Details

### **iOS Workflow Features:**
- ✅ **Automatic code signing** - Codemagic handles certificates
- ✅ **TestFlight submission** - Automatic upload to TestFlight
- ✅ **App Store submission** - Ready for App Store release
- ✅ **Build artifacts** - Downloadable `.ipa` files

### **macOS Workflow Features:**
- ✅ **macOS app builds** - `.app` files for distribution
- ✅ **Code signing** - Developer ID or App Store signing
- ✅ **App Store submission** - Mac App Store ready
- ✅ **Build artifacts** - Downloadable `.app` files

### **Android Workflow Features:**
- ✅ **APK and AAB builds** - Both formats supported
- ✅ **Google Play submission** - Automatic upload to Play Console
- ✅ **Code signing** - Keystore management
- ✅ **Build artifacts** - Downloadable `.apk` and `.aab` files

## 🚀 Build Triggers

### **Automatic Triggers:**
- **Push to main** - Triggers builds automatically
- **Pull requests** - Build and test on PR
- **Tags** - Release builds on version tags

### **Manual Triggers:**
- **Codemagic dashboard** - Manual build initiation
- **CLI tool** - `codemagic-cli` for local builds

## 📱 Build Artifacts

### **iOS Builds:**
- **Location**: Codemagic dashboard → Builds → Artifacts
- **Files**: `.ipa` files (iOS apps)
- **Use**: Install on iOS devices or submit to App Store

### **macOS Builds:**
- **Location**: Codemagic dashboard → Builds → Artifacts
- **Files**: `.app` files (macOS apps)
- **Use**: Distribute via App Store or direct download

### **Android Builds:**
- **Location**: Codemagic dashboard → Builds → Artifacts
- **Files**: `.apk` and `.aab` files
- **Use**: Install on Android devices or submit to Play Store

## 🔑 Environment Variables

### **Required for iOS/macOS:**
```bash
APP_STORE_CONNECT_PRIVATE_KEY=your_private_key
APP_STORE_CONNECT_KEY_IDENTIFIER=your_key_id
APP_STORE_CONNECT_ISSUER_ID=your_issuer_id
```

### **Required for Android:**
```bash
CM_KEYSTORE_PATH=path_to_keystore
CM_KEY_ALIAS=your_key_alias
CM_KEY_PASSWORD=your_key_password
CM_STORE_PASSWORD=your_store_password
```

## 🎯 Benefits of Codemagic

### **✅ Advantages:**
- **Flutter-native** - Built specifically for Flutter
- **Easy setup** - Minimal configuration required
- **Automatic signing** - Handles certificates automatically
- **App Store integration** - Direct submission to stores
- **Fast builds** - Optimized for Flutter apps
- **Free tier** - Generous free plan available

### **🎯 Perfect For:**
- **Flutter developers** - Native Flutter support
- **App Store publishing** - Direct integration
- **Team collaboration** - Easy to share builds
- **Continuous deployment** - Automated releases

## 📋 Next Steps

1. **Set up Codemagic account**
2. **Connect your repository**
3. **Configure environment variables**
4. **Set up code signing**
5. **Run your first build**

## 🆘 Support

- **Codemagic Docs**: https://docs.codemagic.io
- **Flutter Guide**: https://docs.codemagic.io/flutter/flutter-getting-started/
- **Community**: https://codemagic.io/community/

---

**Happy building! 🚀**

For more information, visit:
- [Codemagic Documentation](https://docs.codemagic.io)
- [Flutter CI/CD Guide](https://docs.codemagic.io/flutter/)
- [App Store Connect Setup](https://docs.codemagic.io/publishing-yaml/app-store-connect/) 