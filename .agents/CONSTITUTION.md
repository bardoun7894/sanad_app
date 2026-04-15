# Sanad App Constitution

**Last Updated**: 2026-01-08
**Version**: 1.0.0
**Status**: 100% Complete (120 Features)

---

## Core Principles

### I. The Prime Directive: "Do Not Forgive Progress"

**Context**: The app is considered **100% Complete** (120 Features).

**Rules**:
- NEVER break existing functionality
- NEVER regress the feature count
- NEVER delete features without explicit user approval
- ALWAYS verify impact on existing features before making changes

**Compliance**:
- Before ANY change, verify if it affects an existing feature
- If a change is destructive, **STOP** and ask for user confirmation
- Maintain `docs/FEATURES-STATUS.md` as the holy grail of truth
- Check `docs/FEATURES-COMPLETE.md` before edits

### II. Documentation Authority (Read in Order)

1. `ANTIGRAVITY.md` (Operational Rules for Antigravity IDE)
2. `CLAUDE.md` (Operational Rules for Claude Code)
3. `PROJECT_GUIDE.md` (Architecture & Context)
4. `docs/FEATURES-STATUS.md` (Feature Ledger - 120 Features)
5. `task.md` (Current Objective)

### III. Localization & Accessibility (NON-NEGOTIABLE)

**Mandatory Requirements**:
- NEVER hardcode user-facing text
- ALWAYS use `LanguageProvider` and `app_strings.dart` system
- ALWAYS support both English and French
- ALWAYS support RTL (Right-To-Left) for Arabic layout
- Use `app_strings_en.dart` and `app_strings_fr.dart` for translations

**Enforcement**:
- Any hardcoded text = immediate violation
- All UI text must be retrievable via `context.l10n.keyName`
- Test RTL layout for all new UI components

### IV. Firebase & Security

**Data Access**:
- ALL database operations MUST comply with `firestore.rules`
- NEVER expose sensitive user data without proper authentication
- Use Firestore security rules for all data validation
- Admin operations require `isAdmin: true` verification

**Authentication**:
- Auth state managed through Riverpod providers
- Session persistence handled by Firebase Auth
- No direct user data manipulation without auth checks

### V. State Management (Riverpod)

**Standards**:
- Use `ConsumerWidget` for all stateful widgets
- Use `ref.watch` for reactive state
- Avoid `setState` for business logic
- Providers are the single source of truth

**Architecture**:
- Features use provider-based architecture
- No direct state manipulation
- State changes trigger UI rebuilds automatically

### VI. Routing & Navigation

**GoRouter Standards**:
- Use named routes (defined in `lib/routes/app_router.dart`)
- Handle `context` carefully in async gaps
- Preserve route state during navigation
- Use route guards for protected pages

### VII. Atomic Changes & Testing

**Development Cycle**:
- One logical change per commit
- Read files before editing (NO blind edits)
- Run `flutter analyze` after changes
- Verify feature works before marking complete

**Testing Requirements**:
- Test localization (EN/FR) for new text
- Test RTL layout for Arabic
- Verify Firebase rules compliance
- Check authentication flows

## Project Standards

### File Organization

```
lib/
├── core/
│   ├── l10n/           # Localization (app_strings*.dart)
│   ├── models/         # Data models
│   ├── providers/      # Global providers
│   └── theme/          # Theme & styling
├── features/
│   ├── auth/           # Authentication (Gatekeeper)
│   ├── admin/          # Admin dashboard
│   ├── home/           # Home screen
│   ├── subscription/   # PayPal integration
│   └── [feature]/      # Feature modules
└── routes/
    └── app_router.dart # Master routing registry
```

### Asset Management

- **Images**: `assets/images/` (PNG, JPG)
- **Icons**: `assets/icons/` (prefer SVG)
- **Fonts**: `assets/fonts/`
- All assets declared in `pubspec.yaml`

### Critical Files

1. `lib/routes/app_router.dart` - Master routing registry
2. `lib/core/l10n/` - Localization source of truth
3. `lib/features/auth/` - Authentication gatekeeper
4. `lib/main.dart` - App entry & initialization
5. `firestore.rules` - Database security rules

## Operational Workflow

### Pre-Work Checklist

- [ ] Read `task.md` - What is the specific goal?
- [ ] Check `docs/FEATURES-STATUS.md` - Does this touch completed features?
- [ ] Verify workspace access - `lib/`, `assets/`, `docs/`, `firebase.json`
- [ ] Run `flutter analyze` - Is the codebase clean?

### Implementation Rules

1. **Read First**: Use search/read tools before editing
2. **Atomic Commits**: One logical change per step
3. **Localization First**: No hardcoded text
4. **RTL Support**: Test Right-To-Left layout
5. **Security**: Verify Firestore rules compliance

### Post-Work Verification

- [ ] Update `docs/FEATURES-STATUS.md` if feature added
- [ ] Update `docs/CHANGELOG-YYYY-MM-DD.md` for significant changes
- [ ] Run `flutter analyze` to verify no issues
- [ ] Test the specific feature works

## Technology Stack

**Frontend**: Flutter (Dart)
**State Management**: Riverpod
**Backend**: Firebase (Firestore, Auth, Cloud Functions)
**Routing**: GoRouter
**Localization**: Custom `LanguageProvider` system
**Payment**: PayPal SDK

## Governance

### Constitution Supersedes All

- ALL agents (Antigravity, Claude Code, etc.) MUST follow these rules
- Constitution violations require immediate user notification
- Amendments require documentation and user approval
- Feature regressions are unacceptable without explicit user consent

### Quality Gates

- No feature marked complete without testing
- No PR merged without feature verification
- No documentation debt - update docs with changes
- No localization bypass - all text must be translatable

### Shared Context

This constitution is shared between:
- `.agent/` (Antigravity IDE workflows)
- `.agents/` (Alternative agent commands)
- `.specify/` (Specify system templates & memory)
- Claude Code (via CLAUDE.md)
- Antigravity IDE (via ANTIGRAVITY.md)

**Version**: 1.0.0 | **Ratified**: 2026-01-08 | **Last Amended**: 2026-01-08
