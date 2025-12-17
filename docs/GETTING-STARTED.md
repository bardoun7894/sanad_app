# Getting Started with Sanad App Development

**Last Updated:** 2025-12-17

---

## 🚀 Quick Start

### 1. Initial Setup (First Time Only)

```bash
# Navigate to project
cd /Users/mac/sanad_app

# Install dependencies
flutter pub get

# Build runner (for code generation)
flutter pub run build_runner build

# Run the app
flutter run
```

### 2. Start Your Work Session

```bash
# Pull latest changes
git pull origin master

# Create feature branch
git checkout -b feature/your-feature-name

# Copy documentation template
cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-$(date +%Y-%m-%d)-YOUR-FEATURE.md

# Open in your editor
code .
```

### 3. During Development

- **Update session doc** as you make progress
- **Commit frequently** with meaningful messages
- **Test your changes** with `flutter run`
- **Check formatting** with `dart format lib/`

### 4. Before Committing

```bash
# Format code
dart format lib/

# Analyze code
dart analyze

# Run tests (if applicable)
flutter test

# Check what you're committing
git diff
git diff --cached
```

### 5. Creating a Commit

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat(feature-name): short description

Detailed explanation of what changed and why.
List key changes:
- Change 1
- Change 2
- Change 3"

# Push to remote
git push origin feature/your-feature-name
```

### 6. Final Documentation

Before pushing:
- Complete your `SESSION-YYYY-MM-DD-*.md` file
- Update main docs if needed (`docs/01-ARCHITECTURE.md`, etc.)
- Commit documentation separately

```bash
git add docs/SESSION-YYYY-MM-DD-YOUR-FEATURE.md
git commit -m "docs: add session documentation for [feature name]"
git push origin feature/your-feature-name
```

---

## 📁 Project Structure Quick Reference

### Core Files
```
lib/
├── app.dart                    # Main app configuration
├── main.dart                   # App entry point
└── routes/app_router.dart      # All routes defined here
```

### Core (Shared Code)
```
lib/core/
├── l10n/                       # Localization (Arabic/English/French)
├── models/                     # Shared data models
├── providers/                  # Global providers
├── theme/                      # Design system (colors, typography)
├── widgets/                    # Reusable UI components
└── services/                   # (To implement) API, storage, etc.
```

### Features (Feature-Specific Code)
```
lib/features/
├── home/                       # Home screen
├── chat/                       # Chat screen
├── mood/                       # Mood tracker
├── community/                  # Community posts
├── therapists/                 # Therapist directory & booking
├── profile/                    # User profile & settings
└── notifications/              # (To implement) Notifications
```

---

## 🎯 Current Sprint (Sprint 1)

**Focus:** Backend Integration, Authentication, Local Storage

### What's Needed

1. **Authentication System**
   - Signup screen
   - Login screen
   - Logout functionality
   - Token persistence

2. **API Integration**
   - Setup API client (Dio)
   - Create request/response models
   - Implement error handling

3. **Local Storage**
   - Setup Hive for data persistence
   - Implement mood entry storage
   - Cache API responses

4. **Notifications**
   - Build notifications screen
   - Setup Firebase Cloud Messaging
   - Add notification models and providers

### Where to Start

Choose one task and focus on it:

**Option A: Build Authentication**
- Start: `lib/features/auth/` (create new feature folder)
- Key files:
  - `lib/features/auth/screens/login_screen.dart`
  - `lib/features/auth/screens/signup_screen.dart`
  - `lib/features/auth/providers/auth_provider.dart`
- Documentation: Check `continue.md` section "Authentication"
- Reference: `docs/01-ARCHITECTURE.md` section "Authentication & Security"

**Option B: Setup API Client**
- Start: `lib/core/services/api_client.dart` (create)
- Key files:
  - `lib/core/services/api_client.dart`
  - `lib/core/models/api_response.dart`
  - `lib/core/providers/api_provider.dart`
- Documentation: `docs/02-API-DESIGN.md` (to be created)
- Reference: `docs/01-ARCHITECTURE.md` section "API Integration"

**Option C: Implement Local Storage**
- Start: `lib/core/services/storage_service.dart` (create)
- Key files:
  - `lib/core/services/hive_service.dart`
  - `lib/core/models/stored_data.dart`
  - Update existing providers to use storage
- Documentation: Storage patterns in `docs/01-ARCHITECTURE.md`

---

## 🛠️ Development Commands

### Run App
```bash
# Run on default device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with verbose output
flutter run -v

# Run in profile mode (performance testing)
flutter run --profile

# Run in release mode
flutter run --release
```

### Code Quality
```bash
# Format all code
dart format lib/

# Check for issues
dart analyze

# Run tests
flutter test

# Generate code (for build_runner)
flutter pub run build_runner build

# Watch mode for code generation
flutter pub run build_runner watch
```

### Build
```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build app bundle
flutter build appbundle

# Build for iOS
flutter build ios
```

### Git
```bash
# Check status
git status

# See what changed
git diff

# See commits
git log --oneline -10

# Create branch
git checkout -b feature/name

# Switch branch
git checkout feature/name

# See all branches
git branch -a
```

---

## 📚 Documentation Guide

### Main Documentation Files

1. **00-PROJECT-OVERVIEW.md** - Start here! Project scope, status, sprints
2. **01-ARCHITECTURE.md** - System design, patterns, tech stack
3. **GIT-WORKFLOW.md** - How to use git and document your work
4. **DOCUMENTATION-TEMPLATE.md** - Template for session docs

### Finding Information

```bash
# List all documentation
ls -la docs/

# Search for specific topic
grep -r "authentication" docs/

# Find session docs from a date
ls docs/SESSION-2025-12-*

# View a specific doc
cat docs/01-ARCHITECTURE.md
```

### Creating Documentation

```bash
# Copy template for your session
cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-$(date +%Y-%m-%d)-FEATURE-NAME.md

# Start filling it in as you work
vim docs/SESSION-YYYY-MM-DD-FEATURE-NAME.md

# When complete, commit it
git add docs/SESSION-YYYY-MM-DD-FEATURE-NAME.md
git commit -m "docs: add session documentation for [feature]"
```

---

## 🐛 Troubleshooting

### Flutter Build Issues

**"build/flutter/flutter_assets not found"**
```bash
# Clean build cache
flutter clean

# Rebuild
flutter pub get
flutter run
```

**"Gradle build failed"**
```bash
# Clean gradle cache
cd android && ./gradlew clean && cd ..

# Rebuild
flutter run
```

**"Device not found"**
```bash
# List connected devices
flutter devices

# Start emulator (Android)
emulator -avd <emulator-name>
```

### Code Issues

**"Unresolved reference"**
```bash
# Regenerate code
flutter pub run build_runner build
```

**"Format/Lint errors"**
```bash
# Auto-format
dart format lib/

# Fix analysis issues
# See output of: dart analyze
```

---

## 📝 Commit Message Examples

### Good Examples
```
feat(auth): implement login screen with email validation

- Add login form with email/password fields
- Add form validation logic
- Integrate with AuthProvider
- Add error handling for failed login

Closes #42
```

```
fix(home): fix mood selector not updating state

Root cause: StateProvider wasn't invalidating on mood selection
Solution: Added ref.invalidate() after mood changes
Add test to verify state updates

Closes #45
```

```
docs: add authentication architecture documentation

- Explain auth flow and token management
- Document integration points with UI
- Add code examples for providers
- Reference implementation in session doc
```

---

## 👥 Code Review Checklist

Before creating a PR, verify:

- [ ] Code is formatted: `dart format lib/`
- [ ] No analysis issues: `dart analyze`
- [ ] Tests pass: `flutter test`
- [ ] App builds: `flutter build apk --debug`
- [ ] Session doc is created and complete
- [ ] Commit messages are clear
- [ ] No secrets or sensitive data committed
- [ ] Related documentation updated

---

## 🔗 Quick Links

### Essential Files
- **Project Config:** `pubspec.yaml`
- **App Config:** `lib/app.dart`
- **Routes:** `lib/routes/app_router.dart`
- **Requirements:** `continue.md`

### Key Documentation
- Project Overview: `docs/00-PROJECT-OVERVIEW.md`
- Architecture: `docs/01-ARCHITECTURE.md`
- Git Workflow: `docs/GIT-WORKFLOW.md`
- Session Template: `docs/DOCUMENTATION-TEMPLATE.md`

### Important Directories
- Features: `lib/features/` - One folder per feature
- Core: `lib/core/` - Shared code
- Docs: `docs/` - All documentation

---

## ❓ Common Questions

### Q: How do I add a new feature?

A: Follow these steps:
1. Create feature folder in `lib/features/feature-name/`
2. Create `screens/`, `widgets/`, `models/`, `providers/` subfolders
3. Implement using Riverpod for state management
4. Add route to `lib/routes/app_router.dart`
5. Document in session doc

### Q: Where do I put shared code?

A: Put it in `lib/core/`:
- Widgets → `core/widgets/`
- Models → `core/models/`
- Providers → `core/providers/`
- Services → `core/services/`
- Theme → `core/theme/`

### Q: How do I test my changes?

A: Run `flutter run` and manually test. For unit tests:
```bash
flutter test test/features/your_feature/
```

### Q: What if I make a mistake in git?

A: Check `docs/GIT-WORKFLOW.md` emergency commands section.

### Q: Who do I ask questions?

A: Check documentation first, then review `continue.md` for requirements.

---

## 📞 Support

1. **Check Documentation** - Most questions are answered in `docs/`
2. **Review Code** - Look at similar features for patterns
3. **Check continue.md** - Project requirements and decisions
4. **Create Session Doc** - Document your investigation

---

## 🎓 Next Steps

1. Read `docs/00-PROJECT-OVERVIEW.md` (5 min)
2. Read `docs/01-ARCHITECTURE.md` (15 min)
3. Read `docs/GIT-WORKFLOW.md` (10 min)
4. Choose a Sprint 1 task to work on
5. Create session doc and start coding!

---

**Last Updated:** 2025-12-17

**Questions?** Check the relevant documentation file or review `continue.md` for project requirements.
