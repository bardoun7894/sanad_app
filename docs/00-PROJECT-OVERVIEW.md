# Sanad Mental Health & Wellness App - Project Overview

**Project Name:** Sanad (سند - Support/Assistance in Arabic)
**Type:** Flutter Mobile Application (Mental Health & Wellness Platform)
**Platform:** Android (primary), iOS, Web
**Status:** In Development (Sprint 1)
**Last Updated:** 2025-12-17

---

## 📋 Project Description

Sanad is a comprehensive mental health and wellness application designed for Arabic-speaking communities. It combines AI-powered chat support, mood tracking, community forums, and access to professional therapists.

### Core Features

1. **Mood Tracking** - Daily mood logging with trend analysis
2. **AI Chat Support** - Conversational mental health support
3. **Community Forum** - Anonymous peer support and sharing
4. **Therapist Directory** - Find and book appointments with licensed therapists
5. **Recommendations** - Mood-based exercises, articles, and meditation
6. **Notifications** - Reminders for sessions, exercises, and daily quotes
7. **User Profile** - Settings, stats, and preferences management

---

## 🏗️ Architecture Overview

### Technology Stack

- **Frontend:** Flutter 3.x with Dart
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Localization:** Custom provider (Arabic, English, French)
- **Theme:** Custom design system with dark/light modes
- **Backend:** (To be implemented - Node.js/Express recommended)
- **Database:** (To be decided - Firebase Firestore or PostgreSQL recommended)
- **Authentication:** (To be implemented - Firebase Auth or JWT recommended)
- **Payments:** (To be integrated - Stripe or region-specific gateway)

### Project Structure

```
lib/
├── core/
│   ├── l10n/                 # Localization (Arabic, English, French)
│   ├── models/               # Shared data models
│   ├── providers/            # Global providers (quick actions, profile)
│   ├── theme/                # Design system (colors, typography, shadows)
│   ├── widgets/              # Reusable widgets (buttons, cards, navigation)
│   └── services/             # (To be implemented) API, storage, notifications
├── features/
│   ├── home/                 # Home screen & mood selection
│   ├── chat/                 # AI chat support
│   ├── mood/                 # Mood tracking
│   ├── community/            # Community posts & reactions
│   ├── therapists/           # Therapist listing & booking
│   ├── profile/              # User profile & settings
│   └── notifications/        # (To be implemented) Notifications center
├── routes/                   # Route configuration
└── app.dart                  # Main app widget
```

---

## 📊 Implementation Status

### Completed (UI/UX Layer - 90%)

- ✅ Home Screen with mood selector
- ✅ Chat interface with typing indicators
- ✅ Mood tracker with calendar and history
- ✅ Community posts with emoji reactions
- ✅ Therapist directory and booking UI
- ✅ User profile and settings
- ✅ Core theme and design system
- ✅ Localization framework
- ✅ Routing and navigation

### In Progress / Pending (Functionality - 0%)

- ⏳ Authentication system (login/signup/logout)
- ⏳ Backend API integration
- ⏳ Local data persistence (Hive/SQLite)
- ⏳ Notifications feature
- ⏳ Real chat AI integration
- ⏳ Payment processing
- ⏳ Therapist database
- ⏳ Cloud storage for images

---

## 📅 Development Sprints

### Sprint 1 (Weeks 1-2) - Foundation & Authentication

**Objectives:**
- Setup backend API and authentication
- Implement local data persistence
- Build notifications system
- Connect UI to real data

**Tasks:**
- [ ] Design and setup backend API architecture
- [ ] Implement user authentication (signup, login, logout)
- [ ] Setup local storage (Hive/SharedPreferences)
- [ ] Build notifications feature and Firebase FCM
- [ ] Implement home screen data loading
- [ ] Add daily quote fetching and sharing
- [ ] Build mood recommendations engine

### Sprint 2 (Weeks 3-4) - Chat & Community

**Objectives:**
- Integrate real chat system
- Connect community features to backend
- Add search and filtering

**Tasks:**
- [ ] Integrate AI/therapist chat backend
- [ ] Implement message persistence
- [ ] Connect community posts to database
- [ ] Add post search and advanced filtering
- [ ] Implement user following/blocking
- [ ] Add comment threading

### Sprint 3 (Weeks 5-6) - Bookings & Payments

**Objectives:**
- Implement full booking workflow
- Integrate payment processing
- Therapist management

**Tasks:**
- [ ] Setup therapist database with real data
- [ ] Implement availability calendar
- [ ] Integrate payment gateway (Stripe/local)
- [ ] Build booking confirmation and emails
- [ ] Add session history and ratings
- [ ] Implement cancellation/rescheduling

---

## 🔑 Key Requirements & Constraints

### Functional Requirements

- Must support Arabic, English, and French languages
- Mood-based personalization across all features
- Real-time notifications for bookings and messages
- Therapist availability and calendar management
- Secure payment processing
- Anonymous community posting option
- Mood trend analysis and recommendations

### Non-Functional Requirements

- Target 60fps smooth scrolling
- Support dark/light themes
- Responsive design for various screen sizes
- Offline support for basic features
- <2s load times for main screens
- Modular, testable code architecture

### Constraints

- Android priority (iOS/Web secondary)
- Must comply with mental health data privacy regulations
- Budget-conscious on cloud infrastructure
- Regional payment gateway support needed

---

## 🚀 Quick Start for Developers

### Setup

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run with specific device ID
flutter run -d <device_id>

# Build APK for testing
flutter build apk --debug
```

### Development Commands

```bash
# Format code
dart format lib/

# Analyze code
dart analyze

# Run tests
flutter test

# Generate API client (when implemented)
flutter pub run build_runner build
```

### Key Files to Know

- `lib/app.dart` - Main app configuration
- `lib/routes/app_router.dart` - All route definitions
- `lib/core/theme/` - Design system
- `lib/core/l10n/` - Localization strings
- `lib/features/*/` - Feature-specific code

---

## 📝 Documentation & Knowledge Base

All session documentation is stored in the `docs/` folder:

- `00-PROJECT-OVERVIEW.md` - This file
- `01-ARCHITECTURE.md` - Detailed architecture decisions
- `02-API-DESIGN.md` - API endpoints and contracts
- `03-DATABASE-SCHEMA.md` - Data model documentation
- `04-AUTHENTICATION.md` - Auth flow documentation
- `SESSION-YYYY-MM-DD-*.md` - Timestamped session notes

---

## 🔗 Important Links & Resources

- **Continue Document:** `continue.md` (detailed requirements)
- **Design Reference:** Arab Therapy app
- **Figma Mockups:** (To be provided)
- **API Documentation:** (To be created)

---

## ✋ Support & Questions

When encountering issues or having questions:

1. Check existing documentation in `docs/` folder
2. Review code comments in relevant feature
3. Check `continue.md` for project requirements
4. Create a new session doc for investigation findings

---

**Next Steps:** Start with Sprint 1 - Authentication and Backend API Integration

Last Updated: 2025-12-17
