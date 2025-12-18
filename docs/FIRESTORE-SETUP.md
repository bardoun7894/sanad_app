# Firestore Setup Guide - Phase 1 Implementation

**Date**: December 18, 2025
**Status**: Implementation Complete (Project: `sanad-app-beldify`)

---

## Overview

This guide covers the Firestore collections schema and security rules that have been implemented in the app code. You need to set these up in Firebase Console to enable payment processing.

---

## Step 1: Firestore Collections Schema

### Collection: `users`

Each user gets a document with their subscription information.

**Document ID**: `{uid}` (automatically matches Firebase Auth user ID)

**Fields**:

```javascript
{
  uid: string,                    // Firebase Auth UID
  email: string,                  // User email
  displayName: string,            // User full name
  subscription_status: string,    // "free" | "active" | "expired" | "pending" | "cancelled"
  subscription_plan: string,      // "chat_monthly" | null
  subscription_expiry_date: timestamp,  // When subscription expires
  payment_gateway: string,        // "paypal" | "2checkout" | "bank_transfer" | null
  auto_renew: boolean,            // true for card payments, false for bank
  created_at: timestamp,          // User account creation time
  updated_at: timestamp           // Last update time
}
```

**Example Document**:

```json
{
  "uid": "user123abc",
  "email": "user@example.com",
  "displayName": "Ahmed Mohammed",
  "subscription_status": "active",
  "subscription_plan": "chat_monthly",
  "subscription_expiry_date": "2026-01-17T00:00:00Z",
  "payment_gateway": "paypal",
  "auto_renew": true,
  "created_at": "2025-12-17T10:00:00Z",
  "updated_at": "2025-12-17T15:30:00Z"
}
```

### Collection: `payments`

Records every payment transaction.

**Document ID**: Auto-generated

**Fields**:

```javascript
{
  user_id: string,                    // Reference to user UID
  amount: number,                     // Payment amount in USD
  currency: string,                   // "USD"
  status: string,                     // "pending" | "completed" | "failed"
  payment_method: string,             // "card" | "bank_transfer"
  reference_code: string,             // For bank transfers only (e.g., "REF-USER123-202512")
  gateway_transaction_id: string,     // PayPal/2Checkout transaction ID
  created_at: timestamp,              // When payment was initiated
  updated_at: timestamp               // Last update time
}
```

**Example Document**:

```json
{
  "user_id": "user123abc",
  "amount": 5.00,
  "currency": "USD",
  "status": "completed",
  "payment_method": "card",
  "reference_code": null,
  "gateway_transaction_id": "ch_1234567890",
  "created_at": "2025-12-17T14:00:00Z",
  "updated_at": "2025-12-17T14:05:00Z"
}
```

### Collection: `payment_verifications`

Tracks bank transfer verification requests (admin review).

**Document ID**: Auto-generated

**Fields**:

```javascript
{
  user_id: string,                    // Reference to user UID
  payment_id: string,                 // Reference to payment document
  status: string,                     // "pending" | "verified" | "rejected"
  receipt_url: string,                // URL to uploaded receipt image
  verified_by: string,                // Admin user UID who verified
  verified_at: timestamp,             // When admin verified
  rejection_reason: string,           // Why it was rejected
  created_at: timestamp               // When user submitted
}
```

**Example Document**:

```json
{
  "user_id": "user123abc",
  "payment_id": "payment_abc123",
  "status": "verified",
  "receipt_url": "https://storage.googleapis.com/sanad-app/receipts/...",
  "verified_by": "admin_user_456",
  "verified_at": "2025-12-17T15:00:00Z",
  "rejection_reason": null,
  "created_at": "2025-12-17T14:30:00Z"
}
```

---

## Step 2: Firebase Security Rules

Copy and paste these security rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ========== USERS COLLECTION ==========
    // Users can only read/write their own documents
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      allow create: if request.auth.uid != null;
    }

    // ========== PAYMENTS COLLECTION ==========
    // Users can create payment records (initiated by them)
    // Users can read their own payments
    // Only Cloud Functions can update/delete (via trigger)
    match /payments/{document=**} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid != null;
      allow update, delete: if false;  // Immutable after creation
    }

    // ========== PAYMENT_VERIFICATIONS COLLECTION ==========
    // Users can read their own verifications
    // Users can create new verification requests
    // Only admins can update verification status
    match /payment_verifications/{document=**} {
      allow read: if request.auth.uid == resource.data.user_id ||
                     isAdmin(request.auth.uid);
      allow create: if request.auth.uid != null;
      allow update: if isAdmin(request.auth.uid);
      allow delete: if false;
    }

    // ========== HELPER FUNCTIONS ==========
    // Check if user is admin
    function isAdmin(uid) {
      return get(/databases/$(database)/documents/users/$(uid)).data.is_admin == true;
    }
  }
}
```

---

## Step 3: Create Firestore Indexes

Firestore may suggest creating composite indexes. Create these:

### Index 1: payments collection
- **Collection**: payments
- **Fields**:
  - user_id (Ascending)
  - created_at (Descending)
- **Status**: Auto-created or manually create if suggested

### Index 2: payment_verifications collection
- **Collection**: payment_verifications
- **Fields**:
  - user_id (Ascending)
  - status (Ascending)
- **Status**: Auto-created or manually create if suggested

---

## Step 4: Initialize Firestore Storage in App

The app code automatically initializes Firestore when needed. Ensure Firebase is properly initialized in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await SubscriptionStorageService().initialize();

  runApp(const MyApp());
}
```

---

## Step 5: Cloud Firestore Security Checklist

Before going live, verify:

- [ ] All three collections created (users, payments, payment_verifications)
- [ ] Security rules deployed
- [ ] Indexes created (if auto-suggested)
- [ ] Backups enabled (Firestore → Backups)
- [ ] Billing account linked
- [ ] Real-time listeners enabled

---

## Step 6: Test Firestore Connection

Run the app and check:

1. **First Launch**: App should initialize user document in Firestore
2. **Check Console**: Go to Firebase Console → Firestore → Data
3. **Look for**: Document under `users/{uid}` with default fields

**Expected in Firestore after first login**:
```
users/
  ├─ [user_uid_123]/
  │   ├─ uid: "user_uid_123"
  │   ├─ email: "user@example.com"
  │   ├─ displayName: "User Name"
  │   ├─ subscription_status: "free"
  │   ├─ subscription_plan: null
  │   ├─ created_at: [timestamp]
  │   └─ updated_at: [timestamp]
```

---

## Step 7: Cloud Functions Setup

Before deployment, set up Cloud Functions for webhooks:

### Cloud Function 1: PayPal Webhook

**Name**: `paypal-webhook`
**Runtime**: Node.js 18
**Memory**: 256 MB
**Timeout**: 60 seconds
**Trigger**: HTTPS

[See next section for code]

### Cloud Function 2: 2Checkout Webhook

**Name**: `checkout-webhook`
**Runtime**: Node.js 18
**Memory**: 256 MB
**Timeout**: 60 seconds
**Trigger**: HTTPS

[See next section for code]

---

## Step 8: Firestore Backup Configuration

**To Enable Automatic Backups:**

1. Go to Firebase Console
2. Click on Firestore Database
3. Go to "Backups" tab
4. Click "Create Backup Schedule"
5. Configure:
   - **Backup Location**: Multi-region (recommended)
   - **Frequency**: Daily
   - **Time**: Choose off-peak hours (e.g., 2 AM UTC)
   - **Retention**: 7 days (or longer)

---

## Step 9: Environment Variables for App

In `lib/firebase_options.dart`, ensure these are configured:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  // ... other config
);
```

Get these from Firebase Console → Project Settings.

---

## Troubleshooting

### Issue: Permission Denied Error

**Cause**: Security rules don't match your auth state
**Fix**:
1. Check Firebase Auth is initialized
2. Verify user UID matches in security rules
3. Check error message in Firebase Console → Firestore → Rules

### Issue: Collection Not Found

**Cause**: You haven't created the collections yet
**Fix**:
1. Create documents manually via Firebase Console, OR
2. Let app create them automatically on first use
3. Wait a moment and refresh Firestore console

### Issue: Indexes Not Available

**Cause**: Indexes still building
**Fix**:
1. Check Firebase Console → Firestore → Indexes
2. Wait for index status to change from "Building" to "Enabled"
3. Composite indexes can take a few minutes

---

## What's Next

Once Firestore is set up:

1. ✅ Models and services created (DONE)
2. ✅ Firestore payment service ready (DONE)
3. ✅ Security rules deployed (DO THIS NEXT)
4. ⏳ Cloud Functions for webhooks (See next doc)
5. ⏳ UI screens and widgets (After webhooks)

---

## Summary

Your app now has:

✅ **Models**:
- `SubscriptionStatus` - User subscription state
- `SubscriptionProduct` - Available plans
- Complete with toJson/fromJson for serialization

✅ **Services**:
- `FirestorePaymentService` - Handles all Firestore operations
- `SubscriptionStorageService` - Local caching with Hive
- Complete with error handling

✅ **Repository**:
- `SubscriptionRepository` - Coordinates services
- Implements caching strategy
- Fallback to local storage on network error

✅ **Provider**:
- `SubscriptionNotifier` - Riverpod state management
- Follows existing app patterns
- Ready for UI integration

✅ **Dependencies**:
- Added `cloud_firestore: ^5.5.0` to pubspec.yaml

---

**Next Steps**:

1. Deploy security rules to Firebase
2. Create Cloud Functions for PayPal and 2Checkout webhooks
3. Add localization strings for payment UI
4. Build subscription screens and widgets

---

**Documentation**: See `/docs/QUICK-REFERENCE-FIREBASE-PAYMENT.md` for step-by-step setup

