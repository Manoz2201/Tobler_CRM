# 🚀 GitHub Codespaces Setup for Flutter Development

This guide will help you set up GitHub Codespaces for cross-platform Flutter development, enabling Mac/iOS development from any device.

## 📋 Prerequisites

- GitHub account
- Repository access to [AluminumFormworkCRM](https://github.com/aaryesha17/AluminumFormworkCRM)
- Modern web browser (Chrome, Firefox, Safari, Edge)

## 🎯 Quick Start

### 1. Enable Codespaces

1. Go to your repository: https://github.com/aaryesha17/AluminumFormworkCRM
2. Click the **Code** button
3. Select **Codespaces** tab
4. Click **Create codespace on main**

### 2. First-Time Setup

The codespace will automatically:
- Install Flutter SDK
- Set up development environment
- Install VS Code extensions
- Run `flutter doctor`

## 🛠️ Development Environment

### Pre-installed Tools

- **Flutter SDK**: Latest stable version
- **Dart SDK**: Included with Flutter
- **VS Code Extensions**:
  - Flutter & Dart
  - JSON support
  - Prettier formatting
  - TypeScript support

### Available Commands

```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run tests
flutter test

# Analyze code
flutter analyze

# Build for different platforms
flutter build android --release
flutter build ios --release --no-codesign
flutter build web --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
```

## 📱 Cross-Platform Development

### Android Development
- ✅ Full support in Codespaces
- ✅ Can build APK and App Bundle
- ✅ Emulator available (limited)

### iOS Development
- ✅ Code editing and testing
- ✅ Build iOS apps (no codesign)
- ✅ Use GitHub Actions for full iOS builds

### Web Development
- ✅ Full support
- ✅ Hot reload available
- ✅ Browser testing

### Desktop Development
- ✅ Windows builds via GitHub Actions
- ✅ Linux builds via GitHub Actions
- ✅ macOS builds via GitHub Actions

## 🔄 CI/CD Pipeline

### Automated Builds

The repository includes GitHub Actions workflows for:

1. **iOS/macOS Build** (`.github/workflows/ios-build.yml`)
   - Runs on macOS runners
   - Builds iOS and macOS apps
   - Uploads build artifacts

2. **Android Build** (`.github/workflows/android-build.yml`)
   - Builds APK and App Bundle
   - Uploads to artifacts

3. **Windows Build** (`.github/workflows/windows-build.yml`)
   - Builds Windows executable
   - Uploads to artifacts

4. **Linux Build** (`.github/workflows/linux-build.yml`)
   - Builds Linux executable
   - Uploads to artifacts

### Trigger Builds

Builds are automatically triggered on:
- Push to `main` or `develop` branches
- Pull requests to `main` branch

### Access Build Artifacts

1. Go to your repository
2. Click **Actions** tab
3. Select a workflow run
4. Download artifacts from the bottom

## 🎨 Development Workflow

### 1. Code in Browser
- Edit code directly in VS Code browser interface
- Use all VS Code features (IntelliSense, debugging, etc.)
- Terminal access for commands

### 2. Test Locally
```bash
# Run on web (fastest for testing)
flutter run -d web-server --web-port 8080

# Run tests
flutter test

# Analyze code
flutter analyze
```

### 3. Commit and Push
```bash
git add .
git commit -m "feat: your feature description"
git push origin main
```

### 4. Get Build Artifacts
- Check GitHub Actions for build status
- Download platform-specific builds
- Test on actual devices

## 📦 Build Artifacts

### iOS (.app files)
- Location: GitHub Actions → iOS Build → Artifacts
- Use for testing on iOS devices
- Requires Xcode for full signing

### Android (.apk, .aab files)
- Location: GitHub Actions → Android Build → Artifacts
- Install directly on Android devices
- Ready for Google Play Store

### Windows (.exe files)
- Location: GitHub Actions → Windows Build → Artifacts
- Standalone executable
- No installation required

### Web (static files)
- Location: GitHub Actions → Web Build → Artifacts
- Deploy to any web server
- Works on all browsers

## 🔧 Customization

### Modify Dev Container

Edit `.devcontainer/devcontainer.json` to:
- Add more VS Code extensions
- Install additional tools
- Configure environment variables

### Add Environment Variables

Create `.devcontainer/devcontainer.env`:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
```

## 🚀 Best Practices

### 1. Development
- Use web platform for quick testing
- Write comprehensive tests
- Follow Flutter best practices
- Use proper commit messages

### 2. Building
- Test on multiple platforms
- Use GitHub Actions for consistent builds
- Download and test artifacts regularly
- Keep dependencies updated

### 3. Collaboration
- Use feature branches
- Create pull requests
- Review code thoroughly
- Test on real devices

## 🆘 Troubleshooting

### Common Issues

1. **Flutter not found**
   ```bash
   flutter doctor
   flutter pub get
   ```

2. **Build failures**
   - Check GitHub Actions logs
   - Verify platform-specific requirements
   - Update dependencies

3. **Performance issues**
   - Use web platform for development
   - Limit concurrent builds
   - Monitor resource usage

### Getting Help

- Check [Flutter documentation](https://flutter.dev/docs)
- Review [GitHub Codespaces docs](https://docs.github.com/en/codespaces)
- Open issues in the repository

## 🎉 Benefits

### ✅ Advantages
- **No local setup required**
- **Consistent environment**
- **Cross-platform development**
- **Automatic CI/CD**
- **Team collaboration**
- **Resource efficiency**

### 🎯 Perfect For
- **Cross-platform teams**
- **Remote development**
- **CI/CD automation**
- **Open source projects**
- **Educational purposes**

---

**Happy coding! 🚀**

For more information, visit:
- [Flutter Documentation](https://flutter.dev/docs)
- [GitHub Codespaces](https://docs.github.com/en/codespaces)
- [GitHub Actions](https://docs.github.com/en/actions) 