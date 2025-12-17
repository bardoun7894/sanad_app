# Claude Code Setup Guide

Welcome to the Sanad app! This guide explains how Claude Code is configured to help manage development and documentation.

---

## 📌 What's Been Set Up

### 1. Claude Code Configuration (`.claude/`)

**File:** `.claude/settings.json`
- Project metadata and configuration
- Development workflow settings
- Documentation preferences
- Important file references

**Commands:** `.claude/commands/`
- `/doc` - Create session documentation
- `/status` - Check project status
- `/git-commit` - Structured git commits
- `/review` - Review changes

### 2. Documentation System (`docs/`)

#### Core Documentation (Read These First)
1. **GETTING-STARTED.md** - Quick start guide (START HERE!)
2. **00-PROJECT-OVERVIEW.md** - Project scope and status
3. **01-ARCHITECTURE.md** - System design and patterns
4. **GIT-WORKFLOW.md** - Git and documentation workflow

#### Templates & Reference
- **DOCUMENTATION-TEMPLATE.md** - Template for session docs
- **SESSION-YYYY-MM-DD-*.md** - Session-specific documentation (created per session)

---

## 🚀 Quick Start

### First Time
1. Read `docs/GETTING-STARTED.md` (5 minutes)
2. Read `docs/00-PROJECT-OVERVIEW.md` (10 minutes)
3. Skim `docs/01-ARCHITECTURE.md` (reference later as needed)

### Starting Work
```bash
# Pull latest
git pull origin master

# Create feature branch
git checkout -b feature/your-feature

# Copy template for this session
cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-$(date +%Y-%m-%d)-YOUR-FEATURE.md

# Start coding and update session doc as you go
```

### Ending Work
```bash
# Update session doc with final status
vim docs/SESSION-YYYY-MM-DD-YOUR-FEATURE.md

# Commit everything
git add .
git commit -m "feat(feature): description

Details of changes...

Closes #issue"

# Push
git push origin feature/your-feature-name
```

---

## 📚 Documentation Standards

### Session Documentation

**Every work session should create a SESSION doc:**
```
docs/SESSION-2025-12-17-AUTHENTICATION.md
docs/SESSION-2025-12-18-NOTIFICATIONS.md
docs/SESSION-2025-12-19-BOOKING-INTEGRATION.md
```

**Why?**
- Tracks what was built and why
- Documents issues and solutions
- Preserves architectural decisions
- Makes it easy to find related code
- Prevents knowledge loss

**When?**
- Copy template at start of session
- Update as you work
- Complete before pushing

### Git Commits

**Use Conventional Commits:**
```bash
git commit -m "feat(feature): short description

Longer explanation of what and why.

Closes #123"
```

**Types:** feat, fix, docs, style, refactor, perf, test, chore

**Example:**
```bash
git commit -m "feat(auth): implement login screen

- Add email validation
- Integrate with AuthProvider
- Add error handling

See: docs/SESSION-2025-12-17-AUTHENTICATION.md"
```

---

## 🎯 Current Sprint Status

**Sprint 1 - Backend Integration & Authentication**

### What's Done (UI/UX)
- ✅ Home Screen
- ✅ Chat interface
- ✅ Mood Tracker
- ✅ Community posts
- ✅ Therapist directory
- ✅ User profile
- ✅ Design system & routing

### What's Needed (Functionality)
- ⏳ Authentication system
- ⏳ Backend API
- ⏳ Local storage
- ⏳ Notifications
- ⏳ Real chat integration
- ⏳ Payment processing

**See:** `docs/00-PROJECT-OVERVIEW.md` for full sprint details

---

## 📖 Key Documentation

### Must Read First
1. **docs/GETTING-STARTED.md** - Get coding quickly
2. **docs/GIT-WORKFLOW.md** - Understand git workflow

### Reference As Needed
1. **docs/00-PROJECT-OVERVIEW.md** - Project scope
2. **docs/01-ARCHITECTURE.md** - System design
3. **continue.md** - Original project requirements

### Create As You Go
- **docs/SESSION-YYYY-MM-DD-*.md** - Your work documentation

---

## 🛠️ Key Commands

### Running the App
```bash
flutter run                    # Run on default device
flutter run -d <device-id>    # Run on specific device
flutter build apk --debug     # Build APK
```

### Code Quality
```bash
dart format lib/              # Format code
dart analyze                  # Check for issues
flutter test                  # Run tests
```

### Git
```bash
git checkout -b feature/name  # Create branch
git status                    # See changes
git diff                      # See what changed
git log --oneline -10         # See recent commits
```

### Documentation
```bash
cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-$(date +%Y-%m-%d)-FEATURE.md
ls docs/SESSION-*             # List session docs
grep -r "keyword" docs/       # Search documentation
```

---

## 📁 Project Structure

```
.claude/                          # Claude Code config
├── settings.json               # Project configuration
└── commands/                   # Slash commands
    ├── doc.md
    ├── status.md
    ├── git-commit.md
    └── review.md

docs/                            # All documentation
├── 00-PROJECT-OVERVIEW.md      # Project scope
├── 01-ARCHITECTURE.md          # System design
├── GETTING-STARTED.md          # Quick start (READ THIS!)
├── GIT-WORKFLOW.md             # Git best practices
├── DOCUMENTATION-TEMPLATE.md   # Copy for each session
└── SESSION-*.md                # Session documentation (many)

lib/                             # Application code
├── core/                       # Shared code
├── features/                   # Feature-specific code
├── routes/                     # Navigation
└── app.dart                    # Main app config

continue.md                      # Original requirements (detailed)
README.md                        # Project overview
pubspec.yaml                     # Dependencies
```

---

## ✅ Checklist for Each Session

### Start
- [ ] Pull latest: `git pull origin master`
- [ ] Create branch: `git checkout -b feature/name`
- [ ] Copy template: `cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-YYYY-MM-DD-NAME.md`
- [ ] Open editor: `code .`

### During Work
- [ ] Update session doc as you progress
- [ ] Commit frequently with meaningful messages
- [ ] Test your changes: `flutter run`
- [ ] Format code: `dart format lib/`

### Before Push
- [ ] Analyze code: `dart analyze`
- [ ] Complete session doc
- [ ] Review changes: `git diff`
- [ ] Create final commit

### After Push
- [ ] Create PR with session doc link
- [ ] Wait for review
- [ ] Merge when approved

---

## 🔗 Important Files

### Configuration
- `.claude/settings.json` - Claude Code config
- `pubspec.yaml` - Flutter dependencies
- `.gitignore` - Files to ignore

### App Code
- `lib/app.dart` - Main app
- `lib/routes/app_router.dart` - All routes
- `lib/core/theme/` - Design system
- `lib/core/l10n/` - Localization

### Documentation
- `docs/GETTING-STARTED.md` - Read first!
- `docs/00-PROJECT-OVERVIEW.md` - Project overview
- `docs/01-ARCHITECTURE.md` - System architecture
- `docs/GIT-WORKFLOW.md` - Git guide
- `continue.md` - Original requirements (long)

---

## 🎓 Best Practices

### Documentation
- ✅ Create SESSION doc at start of work
- ✅ Update as you make progress
- ✅ Document issues and solutions
- ✅ Reference in commits

### Git
- ✅ Commit frequently (small, logical units)
- ✅ Use conventional commit format
- ✅ Reference session doc in commits
- ✅ Keep history clean

### Code
- ✅ Format: `dart format lib/`
- ✅ Analyze: `dart analyze`
- ✅ Test: `flutter test`
- ✅ Follow existing patterns

---

## ❓ Frequently Asked Questions

**Q: Where do I start?**
A: Read `docs/GETTING-STARTED.md` (5 min), then pick a Sprint 1 task.

**Q: How do I document my work?**
A: Copy `docs/DOCUMENTATION-TEMPLATE.md` to `docs/SESSION-YYYY-MM-DD-NAME.md` and update as you work.

**Q: What git branch should I use?**
A: `feature/feature-name` for new features, `fix/bug-description` for fixes.

**Q: How do I format commits?**
A: Use conventional commits: `feat(scope): description`. See `docs/GIT-WORKFLOW.md`.

**Q: Where are architectural decisions documented?**
A: In `docs/01-ARCHITECTURE.md` and individual SESSION docs.

**Q: What if I need to understand something quickly?**
A: Check `docs/GETTING-STARTED.md` for quick reference, or search in `docs/` with grep.

---

## 📞 Getting Help

1. **Check documentation** - Most questions answered in `docs/`
2. **Review similar code** - See how other features are implemented
3. **Read continue.md** - Project requirements and design
4. **Create session doc** - Document what you learn

---

## 🎯 Next Steps

1. **Right now:** Read `docs/GETTING-STARTED.md` (5 minutes)
2. **Then:** Read `docs/00-PROJECT-OVERVIEW.md` (10 minutes)
3. **Pick a task:** Choose a Sprint 1 item to work on
4. **Create doc:** Copy `DOCUMENTATION-TEMPLATE.md` for your session
5. **Start coding:** Build and document as you go!

---

## 📝 Summary

**The main idea:**
- Session documentation tracks all work
- Git commits reference documentation
- Future developers can understand decisions
- No knowledge is lost

**Your workflow:**
1. Create feature branch
2. Copy doc template
3. Code and update doc
4. Commit with good messages
5. Push and create PR with doc link

**Key files:**
- `docs/GETTING-STARTED.md` - Read first!
- `docs/00-PROJECT-OVERVIEW.md` - Project overview
- `docs/01-ARCHITECTURE.md` - System design
- `docs/GIT-WORKFLOW.md` - Git guide

---

**Ready to start?** Open `docs/GETTING-STARTED.md` and pick a Sprint 1 task!

Last Updated: 2025-12-17
