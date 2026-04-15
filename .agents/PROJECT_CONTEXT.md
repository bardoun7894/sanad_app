# Sanad App - Shared Project Context

**Last Updated**: 2026-01-08
**Status**: 100% Complete - 31 Features
**Technology**: Flutter + Firebase

---

## Project Overview

Sanad is a healthcare management application supporting:
- **Languages**: English, French, Arabic (RTL)
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Payments**: PayPal Integration
- **State Management**: Riverpod
- **Routing**: GoRouter

---

## Active Features (120 Total)

See `docs/FEATURES-STATUS.md` for complete feature ledger.
See `docs/FEATURES-COMPLETE.md` for detailed feature list.

### Core Modules

1. **Authentication** (`lib/features/auth/`)
   - Login/Logout
   - Session management
   - Role-based access (Admin/User)

2. **Home** (`lib/features/home/`)
   - Dashboard
   - Greeting header
   - Navigation

3. **Admin** (`lib/features/admin/`)
   - User management
   - Patient records
   - Admin dashboard
   - Analytics

4. **Subscription** (`lib/features/subscription/`)
   - PayPal integration
   - Subscription plans
   - Payment history

5. **Localization** (`lib/core/l10n/`)
   - Multi-language support
   - RTL layout support
   - Dynamic language switching

---

## Technology Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Riverpod
- **Navigation**: GoRouter (named routes)
- **UI**: Material Design

### Backend
- **Platform**: Firebase
- **Auth**: Firebase Authentication
- **Database**: Cloud Firestore
- **Functions**: Cloud Functions (Node.js)
- **Storage**: Firebase Storage

### Payment
- **Gateway**: PayPal SDK
- **Service**: `payment_gateway_service.dart`
- **Firestore**: `firestore_payment_service.dart`

---

## File Structure

```
sanad_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   ├── l10n/                 # Localization system
│   │   │   ├── app_strings.dart
│   │   │   ├── app_strings_en.dart
│   │   │   ├── app_strings_fr.dart
│   │   │   └── language_provider.dart
│   │   ├── models/               # Shared data models
│   │   ├── providers/            # Global providers
│   │   └── theme/                # Theme configuration
│   ├── features/
│   │   ├── auth/                 # Authentication module
│   │   ├── admin/                # Admin module
│   │   ├── home/                 # Home module
│   │   ├── subscription/         # Subscription module
│   │   └── splash/               # Splash screen
│   └── routes/
│       └── app_router.dart       # Central routing
├── assets/
│   ├── images/                   # PNG, JPG images
│   ├── icons/                    # SVG icons
│   └── fonts/                    # Custom fonts
├── functions/
│   └── index.js                  # Cloud Functions
├── firestore.rules               # Security rules
├── firestore.indexes.json        # DB indexes
├── docs/                         # Documentation
│   ├── FEATURES-STATUS.md        # Feature ledger
│   ├── FEATURES-COMPLETE.md      # Complete feature list
│   ├── TESTING-CHECKLIST.md      # Test procedures
│   └── CHANGELOG-*.md            # Change logs
├── .agent/                       # Antigravity workflows
├── .agents/                      # Alternative agent commands
└── .specify/                     # Specify system
    ├── memory/                   # Shared context (this file)
    ├── templates/                # Code templates
    └── scripts/                  # Automation scripts
```

---

## Critical Patterns

### 1. Localization Pattern

**NEVER** hardcode text. Always use:

```dart
// In widgets with BuildContext
Text(context.l10n.keyName)

// With Riverpod
Consumer(
  builder: (context, ref, child) {
    final l10n = ref.watch(languageProvider).l10n;
    return Text(l10n.keyName);
  },
)
```

**Add new text**:
1. `app_strings.dart` → `String get keyName;`
2. `app_strings_en.dart` → `@override String get keyName => 'English';`
3. `app_strings_fr.dart` → `@override String get keyName => 'Français';`

### 2. State Management Pattern

**ALWAYS** use Riverpod:

```dart
// Provider definition
final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// Widget consumption
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.value);
  }
}
```

### 3. Routing Pattern

**ALWAYS** use named routes:

```dart
// Navigation
context.go('/home');
context.goNamed('patientDetail', params: {'id': patientId});

// Route definition (app_router.dart)
GoRoute(
  path: '/patient/:id',
  name: 'patientDetail',
  builder: (context, state) => PatientDetailScreen(
    patientId: state.params['id']!,
  ),
)
```

### 4. Firebase Access Pattern

**ALWAYS** verify security rules:

```dart
// Good - uses provider with auth
final patients = ref.watch(patientsProvider);

// Bad - direct access without auth check
FirebaseFirestore.instance.collection('patients').get();
```

---

## Commands

### Development
```bash
flutter run                    # Run app
flutter analyze               # Lint check
flutter test                  # Run tests
flutter pub get               # Install dependencies
```

### Firebase
```bash
firebase deploy --only firestore:rules  # Deploy security rules
firebase deploy --only functions        # Deploy Cloud Functions
firebase emulators:start               # Local testing
```

### Build
```bash
flutter build apk             # Android APK
flutter build appbundle       # Android Bundle
flutter build ios             # iOS build
```

---

## Code Style

### Dart Conventions
- Use `camelCase` for variables and methods
- Use `PascalCase` for classes
- Use `snake_case` for file names
- Prefer `const` constructors where possible
- Use trailing commas for better formatting

### Widget Organization
```dart
class MyWidget extends ConsumerWidget {
  // 1. Constructor & fields
  const MyWidget({Key? key, required this.data}) : super(key: key);
  final String data;

  // 2. Build method
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Logic here
    return _buildUI(context, ref);
  }

  // 3. Private helper methods
  Widget _buildUI(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
```

---

## Common Issues & Solutions

### Issue: Hardcoded Text
**Solution**: Use `context.l10n.keyName` pattern

### Issue: State Not Updating
**Solution**: Verify using `ref.watch()` not `ref.read()`

### Issue: Route Not Found
**Solution**: Check route registered in `app_router.dart`

### Issue: Firebase Permission Denied
**Solution**: Verify `firestore.rules` for the collection

### Issue: RTL Layout Broken
**Solution**: Use `EdgeInsetsDirectional` instead of `EdgeInsets`

---

## Recent Changes

See `docs/CHANGELOG-2026-01-08.md` for latest updates.

---

**This file is shared between all AI agents working on Sanad App.**
**Do NOT modify without updating all referencing systems.**

**Version**: 1.0.0
