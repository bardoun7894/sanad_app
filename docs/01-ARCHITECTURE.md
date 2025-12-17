# Sanad App - Architecture Documentation

**Document Version:** 1.0
**Last Updated:** 2025-12-17
**Status:** Foundation Phase

---

## 🏗️ Overall Architecture

### Layered Architecture Pattern

```
┌─────────────────────────────────────────┐
│         UI Layer (Widgets/Screens)      │  ← User-facing UI
├─────────────────────────────────────────┤
│    State Management Layer (Riverpod)    │  ← Business logic & state
├─────────────────────────────────────────┤
│      Services Layer (API, Storage)      │  ← Data access
├─────────────────────────────────────────┤
│      Models & Domain Layer               │  ← Data structures
├─────────────────────────────────────────┤
│      External Services & APIs           │  ← Firebase, Backend, etc.
└─────────────────────────────────────────┘
```

---

## 📦 Core Packages & Dependencies

### State Management
- **riverpod** (1.2.0+) - Reactive state management
- **flutter_riverpod** - Flutter integration

### Navigation & Routing
- **go_router** - Named routing and deep linking

### Architecture & Code Generation
- **freezed** - Immutable data classes (code generation)
- **json_serializable** - JSON serialization (to be implemented)

### UI & Styling
- **google_fonts** - Typography support
- **intl** - Internationalization (localization)

### Backend Integration (To be added)
- **http** or **dio** - HTTP client
- **hive** or **floor** - Local storage/persistence

### Additional Features (To be added)
- **firebase_messaging** - Push notifications
- **stripe_sdk** or **pay** - Payment processing
- **share_plus** - Content sharing
- **image_picker** - Image selection

---

## 🎯 State Management Pattern (Riverpod)

### Architecture

All business logic uses Riverpod providers for:
- **State Notifiers** - Complex state with methods
- **State Providers** - Simple mutable state
- **Async Providers** - Data fetching and async operations
- **Future Providers** - One-time async operations
- **Stream Providers** - Real-time data streams

### Example Pattern

```dart
// Model
class User {
  final String id, name, email;
  // ...
}

// Provider (simple state)
final selectedMoodProvider = StateProvider<Mood?>((ref) => null);

// Notifier + Provider (complex state)
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.initial());

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      // API call
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### Feature Providers

Each feature has providers for:
- **Current State** - `featureProvider`
- **Filtered/Computed Data** - `filteredFeatureProvider`
- **Single Item** - `featureItemProvider(id)`
- **Async Loading** - `featureFutureProvider`

---

## 🗂️ Directory Structure & Responsibilities

### `/core`
Shared, feature-agnostic code

```
core/
├── l10n/                    # Localization/i18n
│   ├── app_strings.dart       # Arabic strings
│   ├── app_strings_en.dart    # English strings
│   ├── app_strings_fr.dart    # French strings
│   └── language_provider.dart # Language switching logic
├── models/                  # Shared data models
│   ├── quick_action_config.dart
│   └── ...
├── providers/               # Global providers
│   ├── quick_actions_provider.dart
│   └── profile_provider.dart
├── theme/                   # Design system
│   ├── app_colors.dart        # Color palette
│   ├── app_theme.dart         # Material theme
│   ├── app_typography.dart    # Text styles
│   └── app_shadows.dart       # Elevation/shadows
├── widgets/                 # Reusable UI components
│   ├── sanad_button.dart
│   ├── sanad_card.dart
│   ├── bottom_nav_bar.dart
│   └── ...
├── services/                # (To be implemented)
│   ├── api_client.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   └── auth_service.dart
└── constants/               # App constants
    └── app_constants.dart
```

### `/features`
Feature-specific, modular code

Each feature follows this structure:

```
feature_name/
├── screens/                 # Full-page widgets
│   └── feature_screen.dart
├── widgets/                 # Feature-specific components
│   ├── feature_widget_1.dart
│   └── feature_widget_2.dart
├── models/                  # Feature-specific data models
│   └── feature_model.dart
├── providers/               # Feature state management
│   ├── feature_provider.dart
│   └── feature_notifier.dart  # StateNotifier implementation
└── (optional) services/     # Feature-specific services
    └── feature_service.dart
```

---

## 🔄 Data Flow

### Typical Feature Flow

```
┌─────────────────────────────────────────────┐
│  User Interaction (Gesture/Button Press)    │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Widget calls ref.read/ref.watch(provider)  │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  StateNotifier method (e.g., addMood())     │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Call Service/Repository for data access    │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  API call or Local Storage read/write       │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Update state (new state = ...)             │
└────────────────┬──────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  ConsumerWidget rebuilds with new state     │
└─────────────────────────────────────────────┘
```

---

## 🔐 Authentication & Security

### (To be implemented)

**Recommended Approach:**
- Firebase Authentication or JWT-based custom auth
- Secure token storage in platform-specific secure storage
- Refresh token rotation
- Logout clears all cached data

```dart
// Future pattern
class AuthNotifier extends StateNotifier<AuthState> {
  Future<void> signup(String email, String password) async {
    // Call API
    // Store secure token
    // Update auth state
  }

  Future<void> logout() async {
    // Clear secure storage
    // Clear all cached data
    // Reset state
  }
}
```

---

## 💾 Data Persistence

### (To be implemented)

**Recommended Stack:**
- **Hive** for local caching (fast, flutter-optimized)
- **SharedPreferences** for simple key-value pairs
- **Floor** or **Sqflite** for complex queries

```dart
// Hive boxes pattern
class HiveService {
  late Box<MoodEntry> moodBox;
  late Box<User> userBox;

  Future<void> init() async {
    moodBox = await Hive.openBox<MoodEntry>('moods');
    userBox = await Hive.openBox<User>('users');
  }

  Future<void> saveMood(MoodEntry entry) async {
    await moodBox.put(entry.id, entry);
  }
}
```

---

## 🌐 API Integration Pattern

### (To be implemented)

**Recommended Stack:**
- **Dio** for HTTP client (better error handling than http)
- **Retrofit** for code generation (optional)
- Centralized API client with interceptors

```dart
class ApiClient {
  final Dio _dio;

  ApiClient(String baseUrl) {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(AuthInterceptor());
  }

  Future<User> getUser(String id) async {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data);
  }
}

// Usage in provider
final apiClientProvider = Provider((ref) {
  return ApiClient(dotenv.env['API_BASE_URL']!);
});

final userProvider = FutureProvider<User>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getUser('current');
});
```

---

## 🔔 Real-time Features

### (To be implemented)

**Notifications:**
- Firebase Cloud Messaging (FCM) for push notifications
- Local notification scheduling for reminders

**Chat/Messaging:**
- WebSocket for real-time chat (or Firebase Realtime DB)
- Message queue for offline support

```dart
class NotificationService {
  late FirebaseMessaging _fcm;

  Future<void> init() async {
    _fcm = FirebaseMessaging.instance;

    // Request permissions
    await _fcm.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // Show notification
    });
  }
}
```

---

## 🧪 Testing Architecture

### (To be implemented)

**Pattern:**
- Unit tests for providers and notifiers
- Widget tests for UI components
- Integration tests for feature flows

```dart
void main() {
  group('MoodTrackerNotifier', () {
    test('addMood updates state correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(moodTrackerProvider.notifier);

      await notifier.addMood(Mood.happy, 'Good day');

      final state = container.read(moodTrackerProvider);
      expect(state.entries.length, 1);
      expect(state.entries.first.mood, Mood.happy);
    });
  });
}
```

---

## 📱 Performance Considerations

### UI Optimization
- Use `ConsumerWidget` instead of `Consumer` for better performance
- Implement pagination for long lists
- Use `const` constructors where possible
- Leverage Riverpod's automatic memoization

### Data Optimization
- Cache API responses with TTL
- Implement pagination and lazy loading
- Use IndexedStack for tab navigation (keeps widgets in memory)
- Profile with Flutter DevTools

### Network Optimization
- Implement request batching
- Use response compression
- Cache HTTP responses
- Implement exponential backoff for retries

---

## 🔗 Integration Points

### Current (Hardcoded Mock Data)
- Home: Mock quotes and sessions
- Chat: Keyword-based responses
- Mood: Sample entries
- Community: Hardcoded posts
- Therapists: 5 sample therapists

### To be implemented
- **Backend API** - All data fetching
- **Firebase** - Auth, messaging, notifications
- **Stripe/Payment Gateway** - Booking payments
- **Cloud Storage** - Profile pictures, therapist photos
- **Analytics** - User behavior tracking
- **Crash Reporting** - Error tracking

---

## 📋 Next Architecture Tasks

1. **Design API contracts** - Document all endpoints
2. **Setup backend** - Node.js/Express or Firebase
3. **Implement API client** - Dio + interceptors
4. **Add local storage** - Hive or SQLite
5. **Implement authentication** - Signup/Login/Logout
6. **Setup CI/CD** - GitHub Actions or similar
7. **Add testing framework** - Unit/widget tests

---

**Related Documents:**
- `00-PROJECT-OVERVIEW.md` - Project scope
- `02-API-DESIGN.md` - Backend API specification
- `03-DATABASE-SCHEMA.md` - Data models
- `04-AUTHENTICATION.md` - Auth implementation

Last Updated: 2025-12-17
