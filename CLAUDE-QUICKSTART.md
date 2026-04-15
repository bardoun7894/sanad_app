# Claude Code - Quick Start Guide

**How Claude Code Accesses Shared Context with Antigravity IDE**

---

## 🚀 TL;DR - Start Here

Before doing ANY work, Claude should read these 2 files:

1. **`.specify/memory/constitution.md`** - All project rules
2. **`.specify/memory/project-context.md`** - Current state (31 features)

After making changes, run:
```bash
./.specify/scripts/sync-context.sh
```

---

## 📁 The `.specify/` System

The `.specify/` directory is the **shared brain** between Claude Code and Google Antigravity IDE.

### Directory Structure

```
.specify/
├── memory/                         # Shared context (READ THESE)
│   ├── constitution.md             # Master rules - Prime Directive, patterns
│   ├── project-context.md          # Current state - 31 features, tech stack
│   └── last-sync.md               # Last sync status
├── templates/                      # Code templates (USE THESE)
│   ├── flutter-feature-template.md
│   ├── firebase-rules-template.md
│   └── ...
└── scripts/                        # Automation (RUN AFTER CHANGES)
    └── sync-context.sh             # Sync context to all agents
```

---

## 🎯 How to Use in Claude Code

### Step 1: Read Constitution (Every Session)

```
Read: .specify/memory/constitution.md
```

This file contains:
- Prime Directive: "Do Not Forgive Progress" (never break the 31 working features)
- Localization rules (always EN/FR, never hardcode text)
- Firebase security standards
- Riverpod state management patterns
- All mandatory rules

### Step 2: Read Project Context (Every Session)

```
Read: .specify/memory/project-context.md
```

This file contains:
- Current feature count: **31 working features**
- Technology stack (Flutter, Firebase, Riverpod, GoRouter)
- File structure
- Code patterns (localization, state management, routing)
- Common issues and solutions

### Step 3: Use Templates (When Coding)

```
# Adding a new feature?
Read: .specify/templates/flutter-feature-template.md

# Adding Firebase security rules?
Read: .specify/templates/firebase-rules-template.md
```

Templates provide exact boilerplate for:
- Feature modules (screens, providers, models, services)
- Firebase security rules (10 common patterns)
- Localization (EN/FR)
- Riverpod state management

### Step 4: Sync After Changes (After Completing Work)

```bash
# Run this after adding features or updating docs
./.specify/scripts/sync-context.sh
```

This script:
- Counts features from `docs/FEATURES-STATUS.md`
- Updates `.specify/memory/project-context.md` with current count
- Copies files to `.agent/` (Antigravity IDE)
- Generates sync report

---

## 📋 Workflow Examples

### Example 1: Adding a New Feature

```
1. Read constitution and context
   - Read: .specify/memory/constitution.md
   - Read: .specify/memory/project-context.md

2. Read the template
   - Read: .specify/templates/flutter-feature-template.md

3. Implement feature following template structure
   - Create lib/features/[feature]/screens/
   - Create lib/features/[feature]/providers/
   - Create lib/features/[feature]/models/
   - Create lib/features/[feature]/services/
   - Add localization (app_strings.dart, app_strings_en.dart, app_strings_fr.dart)
   - Register route in lib/routes/app_router.dart
   - Add Firebase rules if needed

4. Update documentation
   - Update docs/FEATURES-STATUS.md (increment to 32)
   - Update docs/CHANGELOG-2026-01-08.md

5. Sync context
   - Run: ./.specify/scripts/sync-context.sh
   - Verify: Read: .specify/memory/last-sync.md
```

### Example 2: Adding Localized Text

```
1. Read constitution
   - Read: .specify/memory/constitution.md
   - Section III: Localization & Accessibility

2. Add to localization files (all 3 atomically)
   - Edit: lib/core/l10n/app_strings.dart
   - Edit: lib/core/l10n/app_strings_en.dart
   - Edit: lib/core/l10n/app_strings_fr.dart

3. Verify
   - Check: No hardcoded text
   - Use: context.l10n.keyName pattern
```

### Example 3: Adding Firebase Security Rules

```
1. Read template
   - Read: .specify/templates/firebase-rules-template.md

2. Choose appropriate pattern
   - Admin-only? Use Pattern 1
   - User own data? Use Pattern 2
   - etc.

3. Edit firestore.rules
   - Add rule with pattern
   - Add comments explaining access

4. Verify
   - No "allow read, write: if true" without justification
   - Admin checks use isAdmin()
   - User data checks use request.auth.uid
```

---

## 🔄 Context Synchronization

### Why Sync?

The `.specify/memory/` directory is the **single source of truth**. When you make changes, you need to sync so:
- Antigravity IDE sees your changes
- Feature count is updated
- All agents have the same context

### When to Sync?

Run `./.specify/scripts/sync-context.sh` after:
- Adding/removing features
- Updating `docs/FEATURES-STATUS.md`
- Changing project rules
- Major documentation updates

### What Gets Synced?

```
.specify/memory/constitution.md
  ↓ (copied to)
.agent/CONSTITUTION.md (Antigravity reads this)

.specify/memory/project-context.md
  ↓ (copied to)
.agent/PROJECT_CONTEXT.md (Antigravity reads this)
```

### How to Verify Sync?

```
# Check last sync report
Read: .specify/memory/last-sync.md

# Verify feature count
grep "Status:" .specify/memory/project-context.md
# Should show: **Status**: 100% Complete - 31 Features
```

---

## 📖 Quick Reference

### Key Files for Claude

| File | Purpose | When to Read |
|------|---------|-------------|
| `.specify/memory/constitution.md` | Master rules | Every session start |
| `.specify/memory/project-context.md` | Current state | Every session start |
| `.specify/templates/flutter-feature-template.md` | Feature boilerplate | When adding features |
| `.specify/templates/firebase-rules-template.md` | Security patterns | When adding Firebase rules |
| `docs/FEATURES-STATUS.md` | Feature list | Before changes |
| `CLAUDE.md` | Claude-specific rules | Quick reference |

### Key Commands

```bash
# Sync context
./.specify/scripts/sync-context.sh

# Count features
grep -c "\[x\]" docs/FEATURES-STATUS.md

# Verify no hardcoded text
grep -r "Text('" lib/ --include="*.dart"

# Run analysis
flutter analyze
```

### Key Patterns

**Localization**:
```dart
// GOOD
Text(context.l10n.welcomeMessage)

// BAD
Text('Welcome to Sanad!')
```

**State Management**:
```dart
// GOOD - Riverpod
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.value);
  }
}

// BAD - setState
setState(() { value = newValue; })
```

**Routing**:
```dart
// GOOD - Named routes
context.goNamed('home');

// BAD - Path strings
context.go('/home');
```

---

## ⚠️ Critical Rules

1. **NEVER break existing features** - Read constitution first
2. **NEVER hardcode text** - Always use localization
3. **ALWAYS use Riverpod** - No setState for business logic
4. **ALWAYS sync after changes** - Run sync-context.sh
5. **ALWAYS read templates** - Use consistent patterns

---

## 🔍 Troubleshooting

### "I can't find the constitution"
```
Read: .specify/memory/constitution.md

If file not found:
Run: ./.specify/scripts/sync-context.sh
```

### "Feature count is wrong"
```
# Manually count
grep -c "\[x\]" docs/FEATURES-STATUS.md

# Sync to update
./.specify/scripts/sync-context.sh

# Verify
Read: .specify/memory/project-context.md
```

### "Antigravity doesn't see my changes"
```
# Sync context
./.specify/scripts/sync-context.sh

# Verify sync
ls -la .agent/CONSTITUTION.md .agent/PROJECT_CONTEXT.md

# Check sync report
Read: .specify/memory/last-sync.md
```

---

## 🎓 Learning More

- **Full Setup Guide**: `ANTIGRAVITY-SETUP.md`
- **Specify System**: `.specify/README.md`
- **Architecture**: `PROJECT_GUIDE.md`
- **Antigravity Rules**: `ANTIGRAVITY.md`
- **Claude Rules**: `CLAUDE.md`

---

## ✅ Checklist for Claude

Before starting work:
- [ ] Read `.specify/memory/constitution.md`
- [ ] Read `.specify/memory/project-context.md`
- [ ] Check current feature count (should be 31)
- [ ] Read `task.md` for objective

During work:
- [ ] Use templates from `.specify/templates/`
- [ ] Follow constitution rules
- [ ] No hardcoded text
- [ ] Use Riverpod patterns

After work:
- [ ] Update `docs/FEATURES-STATUS.md` if feature added
- [ ] Run `./.specify/scripts/sync-context.sh`
- [ ] Run `flutter analyze`
- [ ] Verify feature works

---

**Summary**: The `.specify/` directory is your source of truth. Read the constitution and project context at the start of every session, use templates for consistency, and sync after changes so Antigravity IDE stays in sync with your work.

**Current Status**: 31 working features | 100% Complete | Synced with Antigravity IDE ✅
