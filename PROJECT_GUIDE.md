# Sanad App - Universal Project Guide

> **For AI Assistants**: This document provides everything you need to understand and work with the Sanad mental health app. Read this first before making any changes.

---

## Quick Reference

| Property | Value |
|----------|-------|
| **App Name** | Sanad (سند) |
| **Type** | Mental Health & Wellness Platform |
| **Framework** | Flutter 3.x |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend** | Firebase (Firestore, Auth, Storage, FCM) |
| **Languages** | Arabic (primary), English, French |
| **Status** | 100% Complete (120/120 features) |

---

## 1. Project Purpose

Sanad is a comprehensive mental health platform offering:
- **Mood Tracking**: Daily mood logging with insights and recommendations
- **AI Chat Support**: 24/7 AI-powered mental wellness chat
- **Therapist Directory**: Browse, filter, and book licensed therapists
- **Therapist Portal**: Dashboard for therapists to manage bookings and chat
- **Admin Panel**: Complete CMS, user management, analytics, and moderation
- **Community**: Anonymous peer support with posts, comments, and reactions
- **Subscriptions**: Tiered access (Free, Weekly, Basic, Premium, VIP)

---

## 2. Tech Stack

### Frontend
- **Framework**: Flutter 3.x (Dart)
- **State**: flutter_riverpod ^2.6.1
- **Navigation**: go_router ^14.6.2
- **HTTP**: dio ^5.7.0
- **Local Storage**: hive_flutter ^1.1.0
- **Charts**: fl_chart ^0.70.2

### Backend (Firebase)
- **Authentication**: firebase_auth (Email, Google, Apple, Phone OTP)
- **Database**: cloud_firestore
- **Storage**: firebase_storage
- **Push Notifications**: firebase_messaging
- **Analytics**: firebase_analytics
- **Functions**: firebase_functions (Node.js)

### Integration
- **AI**: Gemini API / OpenAI API
- **Payments**: RevenueCat / Stripe / PayPal (simulated)
- **Maps**: google_maps_flutter

---

## 3. Architecture

### Feature-First Structure
```
lib/
├── features/          # Feature modules (auth, home, mood, etc.)
│   ├── [feature]/
│   │   ├── data/      # Repositories, Data Sources, Models
│   │   ├── domain/    # Entities (if clean arch), Logic
│   │   ├── providers/ # Riverpod providers
│   │   ├── screens/   # UI Pages
│   │   └── widgets/   # Feature-specific widgets
├── core/              # Shared utilities, services, theme
├── routes/            # App routing
└── main.dart          # Entry point
```

### State Management Pattern
- **Riverpod** is the strict standard.
- **Providers**: Use `AutoDispose` where possible.
- **AsyncValue**: Handle `data`, `loading`, and `error` states in UI.
- **Controller Pattern**: Logic in `StateNotifier` or `AsyncNotifier`.

### Navigation
- **GoRouter** handles all navigation.
- Use `context.pushNamed` or `context.go` with strict route names from `AppRoutes`.

---

## 4. Key Workflows

### User Journey
1. **Onboarding**: Splash -> Language Selection -> Intro -> Auth
2. **Auth**: Login/Signup -> Profile Setup -> Home
3. **Home**: Dashboard with shortcuts, mood check-in, recent activity
4. **Therapy**: Directory -> Profile -> Booking -> Payment -> Session
5. **Community**: Feed -> Create Post -> Interaction

### Therapist Journey
1. **Login**: Dedicated therapist login
2. **Dashboard**: Appointments, Stats, Income
3. **Session**: Chat/Video interface
4. **Schedule**: Availability management

### Admin Journey
1. **Login**: Admin specific
2. **Dashboard**: App-wide analytics
3. **Management**: Users, Therapists, Content, Reports

---

## 5. Coding Standards

- **Dart**: Strong typing, null safety.
- **Comments**: Documentation comments `///` for public APIs.
- **Strings**: ALL strings must be localized using `Lang` provider (Arabic default).
- **Theme**: Use `Theme.of(context)` and `AppColors`. No hardcoded colors.
- **Responsiveness**: Support Mobile and Tablet (responsive layouts).

---

## 6. Documentation Map

| File | Purpose |
|------|---------|
| `ANTIGRAVITY.md` | Rules for AI Agents (Antigravity/Gemini) |
| `CLAUDE.md` | Rules for AI Agents (Claude) |
| `docs/FEATURES-STATUS.md` | Live status of all 120 features |
| `docs/TESTING-CHECKLIST.md` | Manual verification steps |
| `docs/CHANGELOG-2026-01-04.md` | Detailed changes |
| `firestore.rules` | Security definitions |

---
**Maintained by**: mbardouni44@gmail.com
**Last Updated**: 2026-01-04
