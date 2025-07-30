# Contributing to Aluminum Formwork CRM

Thank you for your interest in contributing to our project! This document provides guidelines and information for contributors.

## 📋 Table of Contents
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Style](#code-style)
- [Git Workflow](#git-workflow)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Release Process](#release-process)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.32.5 or higher
- Dart 3.0 or higher
- Git 2.30 or higher
- Android Studio / VS Code
- Supabase CLI (for database operations)

### Installation
```bash
# Clone the repository
git clone https://github.com/aaryesha17/AluminumFormworkCRM.git

# Navigate to project directory
cd AluminumFormworkCRM

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🔧 Development Setup

### Environment Configuration
1. Copy `.env.example` to `.env.local`
2. Configure your Supabase credentials
3. Set up Firebase configuration (if needed)

### Database Setup
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Apply migrations
supabase db push
```

## 📝 Code Style

### Dart/Flutter Guidelines
- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### File Organization
```
lib/
├── main.dart
├── screens/
│   ├── auth/
│   ├── home/
│   └── settings/
├── widgets/
├── models/
├── services/
├── providers/
└── utils/
```

### Naming Conventions
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`

## 🔄 Git Workflow

### Branch Strategy
1. **main**: Production-ready code
2. **develop**: Integration branch
3. **feature/***: New features
4. **bugfix/***: Bug fixes
5. **hotfix/***: Critical fixes

### Commit Messages
Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(navigation): add mobile navigation bar"
git commit -m "fix(leads): resolve calculation issue"
git commit -m "docs(readme): update installation guide"
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### Test Guidelines
- Write unit tests for business logic
- Write widget tests for UI components
- Aim for >80% code coverage
- Test edge cases and error scenarios

### Test Structure
```
test/
├── unit/
├── widget/
├── integration/
└── mocks/
```

## 📋 Pull Request Process

### Before Submitting
1. Ensure your code follows the style guide
2. Write/update tests for new features
3. Update documentation if needed
4. Test on multiple platforms

### PR Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Screenshots added (if UI changes)

### PR Template
Use the provided PR template and fill in all sections:
- Description of changes
- Testing performed
- Screenshots (if applicable)
- Related issues

## 🚀 Release Process

### Version Bumping
1. Update `VERSION` file
2. Update `pubspec.yaml` version
3. Create release notes
4. Tag the release

### Release Checklist
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Version bumped
- [ ] Release notes written
- [ ] Assets built (APK, Windows, Web)

### Creating a Release
```bash
# Update version
echo "2.3.0" > VERSION

# Commit version bump
git add VERSION
git commit -m "chore(release): bump version to 2.3.0"

# Create tag
git tag -a v2.3.0 -m "Release v2.3.0"

# Push changes
git push origin main
git push origin v2.3.0
```

## 🐛 Bug Reports

### Before Reporting
1. Search existing issues
2. Test on latest version
3. Reproduce the issue
4. Gather relevant information

### Bug Report Template
Use the provided bug report template and include:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Device information
- Screenshots/logs

## 💡 Feature Requests

### Before Requesting
1. Search existing feature requests
2. Consider the impact on existing features
3. Think about implementation complexity
4. Consider platform compatibility

### Feature Request Template
Use the provided feature request template and include:
- Clear problem statement
- Proposed solution
- Platform considerations
- Mockups/screenshots

## 📞 Getting Help

### Communication Channels
- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and ideas
- **Pull Requests**: For code contributions

### Code Review Process
1. Submit PR with detailed description
2. Address review comments
3. Ensure CI/CD passes
4. Merge after approval

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- GitHub contributors page

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to Aluminum Formwork CRM!** 🎉 