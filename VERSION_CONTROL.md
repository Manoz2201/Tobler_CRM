# Version Control & GitHub Integration Guide

## 📋 Overview
This document outlines the version control practices and GitHub integration for the Aluminum Formwork CRM application.

## 🏷️ Versioning Strategy

### Semantic Versioning (SemVer)
We follow [Semantic Versioning 2.0.0](https://semver.org/) format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes, incompatible API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Current Version: `2.2.0`
- **MAJOR**: 2 (Major UI redesigns)
- **MINOR**: 2 (Mobile navigation improvements)
- **PATCH**: 0 (Latest patch)

## 🔄 Git Workflow

### Branch Strategy
```
main (production)
├── develop (development)
├── feature/mobile-navigation
├── feature/lead-management
├── hotfix/critical-bug
└── release/v2.2.0
```

### Branch Naming Convention
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Critical production fixes
- `release/` - Release preparation
- `chore/` - Maintenance tasks

### Commit Message Format
```
type(scope): description

[optional body]

[optional footer]
```

#### Types:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

#### Examples:
```
feat(navigation): add mobile navigation bar with 5-button layout
fix(leads): resolve real-time calculation issue for Total + GST
docs(readme): update installation instructions
style(ui): reduce padding in mobile layout
```

## 🚀 Release Process

### 1. Development Phase
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat(scope): description"

# Push to remote
git push origin feature/new-feature
```

### 2. Code Review
- Create Pull Request on GitHub
- Request reviews from team members
- Address feedback and make changes
- Merge to develop branch

### 3. Release Preparation
```bash
# Switch to develop
git checkout develop
git pull origin develop

# Create release branch
git checkout -b release/v2.3.0

# Final testing and fixes
git commit -m "fix(release): final release fixes"

# Merge to main
git checkout main
git merge release/v2.3.0

# Create and push tag
git tag -a v2.3.0 -m "Release v2.3.0: description"
git push origin v2.3.0
```

### 4. Hotfix Process
```bash
# Create hotfix branch from main
git checkout -b hotfix/critical-bug

# Fix the issue
git commit -m "fix(critical): resolve critical bug"

# Merge to main and develop
git checkout main
git merge hotfix/critical-bug
git tag -a v2.2.1 -m "Hotfix v2.2.1: critical bug fix"

git checkout develop
git merge hotfix/critical-bug
```

## 🔧 GitHub Integration

### Repository Structure
```
AluminumFormworkCRM/
├── .github/
│   ├── workflows/
│   │   ├── ci-cd.yml
│   │   └── release.yml
│   └── ISSUE_TEMPLATE/
├── lib/
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
├── supabase/
├── assets/
├── test/
├── pubspec.yaml
├── README.md
├── VERSION_CONTROL.md
└── .gitignore
```

### GitHub Actions Workflows

#### CI/CD Pipeline (`ci-cd.yml`)
- **Triggers**: Push to main, Pull Request
- **Jobs**:
  - Code Quality (linting, formatting)
  - Build (multi-platform)
  - Security (CodeQL analysis)
  - Deploy Development
  - Deploy Production
  - Notify

#### Release Pipeline (`release.yml`)
- **Triggers**: Tag push (v*)
- **Jobs**:
  - Build Release
  - Create GitHub Release
  - Deploy Release
  - Notify Release

### Branch Protection Rules
- **main**: Require pull request reviews
- **develop**: Require status checks to pass
- **feature/***: Require up-to-date branches

## 📦 Release Assets

### Build Artifacts
- **Android**: `app-release.apk` (23.6MB)
- **Windows**: `Tobler.exe`
- **Web**: Static files for deployment
- **iOS**: Requires macOS build environment

### Release Notes Template
```markdown
## 🎉 Release v2.2.0

### ✨ New Features
- Mobile navigation bar with 5-button layout
- Horizontal scrolling for additional navigation items
- 10px bottom offset for floating design

### 🐛 Bug Fixes
- Fixed real-time calculation for Total + GST
- Resolved mobile layout overflow issues
- Optimized padding for better content visibility

### 🔧 Improvements
- Reduced navigation bar height by 15px
- Enhanced touch targets for mobile
- Improved visual feedback for selected items

### 📱 Mobile Optimizations
- Compact design for better screen utilization
- Responsive layout for different screen sizes
- Touch-friendly navigation elements

### 🔗 Download Links
- [Android APK](link-to-apk)
- [Windows Executable](link-to-exe)
- [Web Version](link-to-web)
```

## 🔐 Security & Secrets

### Repository Secrets
- `SUPABASE_ACCESS_TOKEN` - Supabase API access
- `SUPABASE_DB_PASSWORD` - Database password
- `SUPABASE_DB_URL` - Database connection URL

### Environment Variables
- Development: `.env.development`
- Production: `.env.production`
- Local: `.env.local` (gitignored)

## 📊 Version History

### v2.2.0 (Current)
- Mobile navigation optimization
- 10px bottom offset
- Improved spacing and padding

### v1.2.0
- Mobile navigation redesign
- 5-button layout with horizontal scrolling
- Real-time calculation fixes

### v1.0.0
- Initial release
- Basic CRM functionality
- Lead management system

## 🛠️ Development Tools

### Required Tools
- Git 2.30+
- Flutter 3.32.5+
- Android Studio / VS Code
- GitHub CLI (optional)

### Useful Commands
```bash
# Check version
flutter --version
git --version

# View commit history
git log --oneline --graph

# Check branch status
git status
git branch -a

# Create release
git tag -a v2.3.0 -m "Release v2.3.0"
git push origin v2.3.0

# View tags
git tag -l

# Delete local tag
git tag -d v2.3.0

# Delete remote tag
git push origin --delete v2.3.0
```

## 📞 Support

For version control issues or questions:
1. Check this documentation
2. Review GitHub Issues
3. Contact development team
4. Refer to Git documentation

---

**Last Updated**: December 2024
**Maintainer**: Development Team 