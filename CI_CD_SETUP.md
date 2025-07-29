# CI/CD Pipeline Setup Guide

This guide explains how to set up the CI/CD pipeline for the Flutter CRM app using GitHub Actions with Supabase.

## 🚀 Overview

The CI/CD pipeline includes:
- **Build & Test**: Automated building and testing
- **Code Quality**: Linting and formatting checks
- **Security Scan**: CodeQL security analysis
- **Release Management**: Automated releases
- **Deployment**: Supabase deployment

## 📁 Workflow Files

### 1. Main CI/CD Pipeline (`.github/workflows/ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
- **Build & Test**: Compiles app, runs tests, creates artifacts
- **Code Quality**: Analyzes code, checks formatting
- **Security Scan**: Performs security analysis
- **Deploy**: Deploys to Supabase (main branch only)

### 2. Release Management (`.github/workflows/release.yml`)

**Triggers:**
- Push tags starting with `v*` (e.g., `v1.0.0`)

**Actions:**
- Builds APK and Web versions
- Creates GitHub release with artifacts
- Generates release notes automatically

## 🔧 Setup Instructions

### 1. Repository Setup

1. **Enable GitHub Actions:**
   - Go to your repository settings
   - Navigate to "Actions" → "General"
   - Enable "Allow all actions and reusable workflows"

2. **Set up branch protection:**
   - Go to "Branches" → "Add rule"
   - Protect `main` branch
   - Require status checks to pass before merging

### 2. Supabase Setup (for deployment)

1. **Install Supabase CLI:**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase:**
   ```bash
   supabase login
   ```

3. **Initialize Supabase in your project:**
   ```bash
   supabase init
   ```

4. **Get Supabase Access Token:**
   - Go to Supabase Dashboard → Account → Access Tokens
   - Generate new access token
   - Save the token securely

### 3. GitHub Secrets Setup

Add these secrets to your repository (Settings → Secrets and variables → Actions):

1. **SUPABASE_ACCESS_TOKEN**
   - Value: Your Supabase access token
   - Used for Supabase CLI authentication

2. **SUPABASE_DB_PASSWORD**
   - Value: Your Supabase database password
   - Used for database operations

3. **GITHUB_TOKEN** (usually auto-provided)
   - Used for creating releases and uploading artifacts

### 4. Update Configuration

1. **Update Supabase Project Reference:**
   - In `.github/workflows/ci-cd.yml`
   - Update the deployment commands based on your Supabase setup

2. **Update Flutter Version:**
   - In both workflow files
   - Update `flutter-version: '3.24.5'` to your desired version

## 🎯 Usage

### Creating a Release

1. **Create and push a tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Monitor the release:**
   - Go to GitHub → Actions
   - Watch the "Release Management" workflow
   - Check the generated release in Releases tab

### Manual Deployment

1. **Push to main branch:**
   ```bash
   git push origin main
   ```

2. **Monitor deployment:**
   - Check Actions tab for deployment status
   - Verify deployment on Supabase Dashboard

## 📊 Pipeline Stages

### Stage 1: Build & Test
- ✅ Install dependencies
- ✅ Run code analysis
- ✅ Execute tests
- ✅ Build APK and Web versions
- ✅ Upload artifacts

### Stage 2: Code Quality
- ✅ Run linter with non-fatal warnings
- ✅ Check code formatting
- ✅ Ensure code style consistency

### Stage 3: Security Scan
- ✅ Initialize CodeQL
- ✅ Perform security analysis
- ✅ Generate security reports

### Stage 4: Deploy (Main Branch Only)
- ✅ Build production version
- ✅ Deploy to Firebase Hosting
- ✅ Update live channel

## 🔍 Monitoring

### GitHub Actions Dashboard
- Go to your repository → Actions
- View workflow runs and their status
- Check logs for any failures

### Supabase Dashboard
- Monitor database deployments
- Check Edge Functions
- Manage project settings

## 🛠️ Troubleshooting

### Common Issues

1. **Build Failures:**
   - Check Flutter version compatibility
   - Verify all dependencies are properly declared
   - Review build logs for specific errors

2. **Deployment Failures:**
   - Verify Supabase access token is correct
   - Check Supabase project configuration
   - Ensure Supabase CLI is properly configured

3. **Security Scan Issues:**
   - Review CodeQL analysis results
   - Address any security vulnerabilities
   - Update dependencies if needed

### Debug Commands

```bash
# Test locally
flutter analyze
flutter test
flutter build apk --release
flutter build web --release

# Check Supabase configuration
supabase projects list
supabase status
```

## 📈 Best Practices

1. **Branch Strategy:**
   - Use feature branches for development
   - Merge to `develop` for testing
   - Merge to `main` for production

2. **Version Management:**
   - Use semantic versioning (v1.0.0)
   - Create releases for significant changes
   - Document changes in release notes

3. **Security:**
   - Regularly update dependencies
   - Monitor security scan results
   - Keep secrets secure

4. **Testing:**
   - Write comprehensive tests
   - Test on multiple platforms
   - Validate deployment before release

## 🎉 Success Metrics

- ✅ All builds pass
- ✅ Code quality standards met
- ✅ Security scans clean
- ✅ Successful deployments
- ✅ Automated releases working

## 📞 Support

For issues with the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review Firebase deployment status
3. Verify configuration settings
4. Contact development team

---

**Last Updated:** December 2024
**Version:** 1.0.0 