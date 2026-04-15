# Sanad App - Antigravity AI Rules

> **Strict Operational Protocols**: These rules are mandatory for maintaining the 100% completion status of the Sanad App.

---

## 1. The Prime Directive: "Do Not Forgive Progress"

**Context**: The app is considered **100% Complete** (120 Features).
**Rule**: NEVER break existing functionality. NEVER regress the feature count.
**Action**:
- Before ANY change, verify if it affects an existing feature.
- If a change is destructive, **STOP** and ask for user confirmation.
- Maintain the `docs/FEATURES-STATUS.md` file as the holy grail of truth.

---

## 2. The Mirror Check (Mandatory)

**Before sending ANY tool call that edits code:**
1. **PAUSE**.
2. **ASK**: "Does this change delete, break, or hide one of the 120 features?"
3. **CHECK**: Look at `docs/FEATURES-COMPLETE.md`.
4. **VERIFY**: If unsure, read the feature code first.

*You are not just a coder. You are the auditor of your own work.*

---

## 2. Documentation Authority

You must read and adhere to these files in order:
1. `ANTIGRAVITY.md` (This file - Operational Rules)
2. `PROJECT_GUIDE.md` (Architecture & Context)
3. `docs/FEATURES-STATUS.md` (Feature Ledger)
4. `task.md` (Current Objective)

---

## 3. Operational Checklists

### Pre-Work Checklist
- [ ] **Read `task.md`**: What is the specific goal?
- [ ] **Check `docs/FEATURES-STATUS.md`**: Does this touch completed features?
- [ ] **Verify Workspace**: Do I have access to `lib/`, `assets/`, `docs/`, `firebase.json`?
- [ ] **Run Analysis**: `flutter analyze` clean?

### Implementation Rules
- **Atomic Commits**: One logical change per step.
- **No Blind Edits**: Read the file before writing. Use `view_file` or `grep_search`.
- **Localization First**: NEVER hardcode text. Use `LanguageProvider` / `app_strings`.
- **RTL Support**: Always test/consider Right-To-Left layout for Arabic.

### Post-Work Verification
- [ ] **Update Docs**: Did I add a feature? Update `FEATURES-STATUS.md`.
- [ ] **Update Changelog**: Log significant changes in `docs/CHANGELOG-*.md`.
- [ ] **Lint Check**: Run `flutter analyze`.
- [ ] **Test**: Verify the specific feature works.

---

## 4. Communication Protocol

- **User Notification**: Use `notify_user` for blocking questions or critical reviews.
- **Commit Messages**: Use conversational but precise summaries in `task_boundary`.
- **Artifacts**: Use `implementation_plan.md` for planning large changes (5+ files).

---

## 5. Tech Specifics (Sanad App)

- **Firebase**: Always verify `firestore.rules` compliance when changing data access.
- **Riverpod**: Use `ConsumerWidget` and `ref.watch`. Avoid `setState` for business logic.
- **GoRouter**: Use named routes. Handle `context` carefully in async gaps.
- **Assets**: All images in `assets/images/`, icons in `assets/icons/`. SVG preferred for icons.

---

## 6. Critical Files

- `lib/routes/app_router.dart`: Master routing registry.
- `lib/core/l10n/`: Localization source.
- `lib/features/auth/`: Authentication logic (Gatekeeper).
- `lib/main.dart`: App entry & initialization.

---

> **Final Note**: You are the guardian of this codebase. Treat it with the respect due a finished, production-ready product.
