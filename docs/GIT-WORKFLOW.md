# Git Workflow & Documentation Management

**Last Updated:** 2025-12-17

---

## 📋 Overview

This document describes how to use git effectively with the Sanad app project while maintaining comprehensive documentation of all changes.

---

## 🔄 Git Workflow

### Branch Strategy

**Main Branches:**
- `master` - Production-ready code, tagged with version numbers
- `develop` - Integration branch for features (if team project)

**Feature Branches:**
- Name format: `feature/feature-name`
- Example: `feature/authentication`, `feature/notifications`
- Created from: `master` (or `develop` if using git-flow)
- Deleted after: PR merge

**Bug Fix Branches:**
- Name format: `fix/bug-description`
- Example: `fix/chat-message-scroll-bug`

**Documentation Branches:**
- Name format: `docs/document-name`
- Example: `docs/api-design`, `docs/database-schema`

### Typical Feature Workflow

```bash
# 1. Create feature branch
git checkout -b feature/authentication

# 2. Make changes
# ... implement your feature ...

# 3. Create documentation (see below)
# ... copy SESSION-YYYY-MM-DD-*.md template ...

# 4. Stage all changes
git add .

# 5. Commit with meaningful message
git commit -m "feat: add email/password authentication

- Implement login and signup screens
- Add auth state management with Riverpod
- Integrate with backend API
- Add token persistence with secure storage

Closes #123"

# 6. Push to remote
git push origin feature/authentication

# 7. Create Pull Request with documentation

# 8. After review and merge
git checkout master
git pull origin master
git branch -d feature/authentication
```

---

## 📝 Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat** - New feature
- **fix** - Bug fix
- **docs** - Documentation only
- **style** - Code style (formatting, missing semicolons, etc)
- **refactor** - Code refactor without feature/fix changes
- **perf** - Performance improvement
- **test** - Adding or updating tests
- **chore** - Build, CI/CD, dependencies

### Examples

```bash
# Good commit messages
git commit -m "feat(auth): add login screen with email validation"
git commit -m "fix(chat): prevent infinite scroll loop"
git commit -m "docs(api): add payment endpoint documentation"
git commit -m "perf(home): optimize mood selector rendering"

# Bad commit messages (avoid)
git commit -m "updates"
git commit -m "fix stuff"
git commit -m "WIP"
```

---

## 📚 Documentation Process

### Before Starting Work

1. **Check existing documentation**
   ```bash
   ls docs/
   grep -r "your-feature" docs/
   ```

2. **Review related session docs**
   - Look for similar work
   - Understand previous decisions
   - Check for known issues

### During Development

1. **Create session documentation file**
   ```bash
   # Copy template
   cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-2025-12-17-AUTHENTICATION.md
   ```

2. **Fill in as you work**
   - Update objective
   - List tasks as you complete them
   - Document issues and solutions in real-time
   - Track files changed

3. **Keep notes on decisions**
   - Why did you choose Riverpod over Bloc?
   - Why this architecture pattern?
   - What alternatives did you consider?

### After Completing Feature

1. **Update main architecture doc** (if needed)
   ```bash
   # Update if you changed architecture
   vim docs/01-ARCHITECTURE.md
   ```

2. **Complete session doc**
   - Mark all tasks complete
   - Add testing results
   - Document next steps
   - Add sign-off date

3. **Create comprehensive commit message**
   ```bash
   # With detailed body explaining what and why
   git commit -m "feat(auth): implement email/password authentication

   Implementation Details:
   - Added AuthNotifier with login/signup/logout methods
   - Integrated with secure token storage (Keychain/Keystore)
   - Added proper error handling and validation
   - Implemented GoRouter redirect for auth state

   Architecture:
   - Used Riverpod StateNotifier for state management
   - Separated concerns: UI/Providers/Services
   - Added platform-specific secure storage

   Testing:
   - Added 12 unit tests for AuthNotifier
   - Added widget tests for login/signup screens
   - Manual testing: all flows verified

   Closes #15

   See: docs/SESSION-2025-12-17-AUTHENTICATION.md"
   ```

4. **Commit documentation separately** (optional)
   ```bash
   git add docs/SESSION-2025-12-17-AUTHENTICATION.md
   git commit -m "docs: add session documentation for authentication feature"
   ```

---

## 🔗 Pull Request Checklist

When creating a PR, use this template:

```markdown
## Description
Brief description of what this PR does

## Related Issue
Closes #123

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation
- [ ] Breaking change

## Changes Made
- List specific changes
- Reference files modified

## Testing Done
- [ ] Unit tests passing
- [ ] Widget tests passing
- [ ] Manual testing completed

## Documentation
- [ ] Code comments added
- [ ] Session doc created: docs/SESSION-YYYY-MM-DD-*.md
- [ ] Architecture doc updated (if applicable)
- [ ] API doc updated (if applicable)

## Checklist
- [ ] Code follows style guidelines
- [ ] No console errors or warnings
- [ ] Performance impact reviewed
- [ ] Security considerations addressed
```

---

## 📖 Documentation Hierarchy

### 1. Main Documentation (Updated when architecture changes)
```
docs/
├── 00-PROJECT-OVERVIEW.md      # Project scope & status
├── 01-ARCHITECTURE.md          # System design & patterns
├── 02-API-DESIGN.md            # Backend API spec
├── 03-DATABASE-SCHEMA.md       # Data models
├── 04-AUTHENTICATION.md        # Auth flow & implementation
└── GIT-WORKFLOW.md             # This file
```

### 2. Session Documentation (Created for each work session)
```
docs/
├── SESSION-2025-12-17-AUTHENTICATION.md
├── SESSION-2025-12-18-NOTIFICATIONS.md
├── SESSION-2025-12-19-CHAT-INTEGRATION.md
└── ...
```

### 3. Inline Code Documentation (In source files)
```dart
// File: lib/features/auth/providers/auth_provider.dart

/// Manages user authentication state including login, signup, and logout.
///
/// State transitions:
/// - initial → loading → authenticated/error
/// - authenticated → loading → unauthenticated
///
/// Uses platform-specific secure storage for token persistence.
class AuthNotifier extends StateNotifier<AuthState> {
  // ...
}
```

---

## 🔍 Finding Documentation

### Search by Feature
```bash
# Find docs about authentication
grep -r "authentication\|auth\|login" docs/

# Find docs about specific file changes
grep -r "lib/features/chat" docs/
```

### Search by Date
```bash
# Find all docs from a week
ls docs/SESSION-2025-12-*

# Find latest session doc
ls -t docs/SESSION-* | head -1
```

### Search by Issue
```bash
# Find PRs/docs that closed specific issue
grep -r "Closes #123" docs/
grep -r "#123" .git/logs/
```

---

## 🚫 What NOT to Commit

Files to exclude (already in .gitignore):
```
# Build directories
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# IDE files
.idea/
.vscode/
*.iml

# OS files
.DS_Store
Thumbs.db

# Environment files
.env
.env.local
google-services.json
Info.plist (sensitive config)

# Dependencies
pubspec.lock  # (usually included, but check team preference)
```

### Never Commit
- API keys or credentials
- Sensitive user data
- Large binary files (>10MB)
- IDE-specific workspace settings
- Local environment configurations

---

## 📝 Commit Frequency

### Good Practices
- ✅ Commit after completing each logical unit
- ✅ Commit after fixing bugs
- ✅ Commit after updating documentation
- ✅ Create separate commits for refactoring vs features

### Examples
```bash
# Good: Logical units
git commit -m "feat(auth): add login screen UI"
git commit -m "feat(auth): implement login logic"
git commit -m "test(auth): add login screen tests"

# Avoid: Too many unrelated changes
git commit -m "feat: everything"

# Avoid: Incomplete features
git commit -m "WIP: auth almost done"
```

---

## 🔄 Keeping Commits Clean

### Squash Commits Before Merge
```bash
# If you have multiple commits on your branch
git rebase -i origin/master

# Mark commits to squash
# pick a1b2c3d first commit
# squash e4f5g6h second commit
# squash i7j8k9l third commit
```

### Amend Last Commit
```bash
# Fix mistake in last commit
git add .
git commit --amend -m "corrected message"

# Don't do this if already pushed to shared repo!
```

---

## 🔗 Useful Git Commands

### View Logs
```bash
# See all commits with details
git log --oneline --graph --all

# See commits for specific file
git log -- lib/features/chat/chat_screen.dart

# See commits in session docs
git log --grep="SESSION" --oneline
```

### Find When Changes Happened
```bash
# Who changed this line and when?
git blame lib/features/auth/screens/login_screen.dart

# See specific change
git show a1b2c3d
```

### Understand Changes
```bash
# Diff uncommitted changes
git diff

# Diff staged changes
git diff --cached

# Diff between branches
git diff master feature/auth
```

### Emergency Commands
```bash
# Undo uncommitted changes
git checkout -- lib/features/chat/chat_screen.dart

# Undo staged changes
git reset HEAD lib/features/chat/chat_screen.dart

# See what you're about to lose
git reflog

# Go back to previous state
git reset --hard HEAD~1  # CAREFUL! This loses changes!
```

---

## 👥 Team Collaboration

### Code Review Checklist
When reviewing someone's code:

1. **Check documentation**
   - Is there a session doc?
   - Is it complete and accurate?
   - Are architecture decisions explained?

2. **Check implementation**
   - Does it match stated design?
   - Are there obvious bugs?
   - Is performance acceptable?

3. **Check tests**
   - Are critical paths tested?
   - Do tests pass?
   - Is coverage adequate?

4. **Check commits**
   - Are commit messages clear?
   - Is history clean?
   - Any unrelated changes?

### Approval Process

```
Reviewer → Comments/Requests → Developer → Updates → Resubmit → Approve → Merge
```

---

## 📋 Example Session

### Start of Day
```bash
# Pull latest changes
git pull origin develop

# Create feature branch
git checkout -b feature/notifications

# Copy documentation template
cp docs/DOCUMENTATION-TEMPLATE.md docs/SESSION-2025-12-20-NOTIFICATIONS.md
```

### During Day
```bash
# Work on feature...
# Update SESSION-2025-12-20-NOTIFICATIONS.md as you go

# Commit logical units
git add lib/features/notifications/models/
git commit -m "feat(notifications): add notification data models"

git add lib/features/notifications/providers/
git commit -m "feat(notifications): implement notification state management"

git add lib/features/notifications/screens/
git commit -m "feat(notifications): add notification screen UI"
```

### End of Day
```bash
# Update session documentation with final notes
vim docs/SESSION-2025-12-20-NOTIFICATIONS.md

# Commit documentation
git add docs/SESSION-2025-12-20-NOTIFICATIONS.md
git commit -m "docs: add session documentation for notifications feature"

# Push to remote
git push origin feature/notifications

# Create Pull Request on GitHub/GitLab
# (Include link to session documentation)
```

---

## 🎓 Best Practices Summary

1. **Commit Often** - Small, logical commits are easier to review and revert if needed
2. **Write Good Messages** - Help your future self understand why changes were made
3. **Document As You Go** - Update session docs in real-time, don't leave it for the end
4. **Keep History Clean** - Use rebase and squash when appropriate
5. **Review Before Commit** - Use `git diff` to double-check what you're committing
6. **Reference Issues** - Link commits to issue trackers (e.g., "Closes #123")
7. **Update Main Docs** - Keep architecture/API docs in sync with code
8. **Comment in Code** - Explain WHY not WHAT in comments

---

## 🔗 Related Documents

- `00-PROJECT-OVERVIEW.md` - Project scope
- `DOCUMENTATION-TEMPLATE.md` - Template for session docs
- Any `SESSION-*.md` files - Previous session documentation

---

**Last Updated:** 2025-12-17

For questions about git workflow, check the template and this guide first!
