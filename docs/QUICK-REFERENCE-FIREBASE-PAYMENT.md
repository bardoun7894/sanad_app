# Firebase Payment System - Quick Reference Card

**Status**: Ready to implement
**Estimated Time**: 3-4 days for Phase 1
**Prerequisites**: Firebase project already created, Firebase Auth integrated

---

## ⚡ Quick Start - Firebase Payment Setup

### Step 1: Enable Firestore (15 minutes)

```bash
# In Firebase Console:
1. Go to Firestore Database
2. Click "Create Database"
3. Choose: Production mode
4. Region: nearest to your users (e.g., europe-west1)
5. Click "Create"
```

### Step 2: Create Collections in Firestore (10 minutes)

Run in Firestore Console or via Cloud Shell:

```javascript
// Collection: users
// Document ID: {uid} (auto-generated from auth)
{
  uid: "user123",
  email: "user@example.com",
  displayName: "John Doe",
  subscription_status: "free", // "free" | "active" | "expired" | "pending"
  subscription_plan: null, // "chat_monthly" when subscribed
  subscription_expiry_date: null, // timestamp
  payment_gateway: null, // "paypal" | "2checkout" | "bank_transfer"
  auto_renew: false,
  created_at: timestamp,
  updated_at: timestamp
}

// Collection: payments
// Document ID: auto-generated
{
  user_id: "user123",
  amount: 5.00,
  currency: "USD",
  status: "pending", // "pending" | "completed" | "failed"
  payment_method: "card", // "card" | "bank_transfer"
  reference_code: "REF-USER123-202512", // for bank transfers
  gateway_transaction_id: "ch_xxxx", // PayPal/2Checkout ID
  created_at: timestamp,
  updated_at: timestamp
}

// Collection: payment_verifications
// Document ID: auto-generated
{
  user_id: "user123",
  payment_id: "payment_xxx",
  status: "pending", // "pending" | "verified" | "rejected"
  receipt_url: "https://...", // uploaded by user
  verified_by: "admin_user_123",
  verified_at: null,
  rejection_reason: null,
  created_at: timestamp,
  updated_at: timestamp
}
```

### Step 3: Set Up Security Rules (5 minutes)

Replace Firestore Security Rules with:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Payments are write-only for users (created via Cloud Function)
    match /payments/{document=**} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow create: if request.auth.uid != null;
      allow update, delete: if false; // Immutable after creation
    }

    // Payment verifications - admin only
    match /payment_verifications/{document=**} {
      allow read: if request.auth.uid == resource.data.user_id ||
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.is_admin == true;
    }
  }
}
```

### Step 4: Create Cloud Functions (20 minutes)

**Function 1: PayPal Webhook Handler**

```bash
# In Firebase Console → Cloud Functions → Create Function

Name: paypal-webhook
Runtime: Node.js 18
Memory: 256 MB
Timeout: 60 seconds

Trigger: HTTPS
Authentication: Require authentication (unchecked for webhook)
```

```javascript
// index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.paypalWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { event_type, resource } = req.body;

    if (event_type === 'BILLING.SUBSCRIPTION.CREATED') {
      const customId = resource.custom_id;
      const subscriptionId = resource.id;

      // Update user subscription
      await db.collection('users').doc(customId).update({
        subscription_status: 'active',
        subscription_plan: 'chat_monthly',
        subscription_expiry_date: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        ),
        payment_gateway: 'paypal',
        auto_renew: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });

      // Send push notification
      await admin.messaging().sendToTopic(customId, {
        notification: {
          title: 'Subscription Active',
          body: 'Your chat subscription is now active'
        }
      });

      res.json({ success: true });
    } else if (event_type === 'BILLING.SUBSCRIPTION.CANCELLED') {
      const customId = resource.custom_id;

      await db.collection('users').doc(customId).update({
        subscription_status: 'cancelled',
        auto_renew: false,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });

      res.json({ success: true });
    } else {
      res.json({ ignored: true });
    }
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: error.message });
  }
});
```

**Function 2: 2Checkout Webhook Handler**

```javascript
exports.checkoutWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { event_type, data } = req.body;

    if (event_type === 'subscription_activated') {
      const userId = data.custom_product_id;
      const orderId = data.order_id;

      await db.collection('users').doc(userId).update({
        subscription_status: 'active',
        subscription_plan: 'chat_monthly',
        subscription_expiry_date: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        ),
        payment_gateway: '2checkout',
        auto_renew: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp()
      });

      await admin.messaging().sendToTopic(userId, {
        notification: {
          title: 'Subscription Active',
          body: 'Your chat subscription is now active'
        }
      });

      res.json({ success: true });
    }
  } catch (error) {
    console.error('2Checkout webhook error:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### Step 5: Deploy Cloud Functions

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize in project root
firebase init functions

# Deploy
firebase deploy --only functions
```

---

## 📱 App Integration Quick Checklist

### To Do Before Starting Implementation

- [ ] Firestore collections created (users, payments, payment_verifications)
- [ ] Security rules deployed
- [ ] Cloud Functions deployed and tested
- [ ] PayPal webhook URL configured: `https://[region]-[project].cloudfunctions.net/paypalWebhook`
- [ ] 2Checkout webhook URL configured similarly
- [ ] Google Play Services configured in android/app/build.gradle
- [ ] ios/Podfile updated for Firebase

### Files to Create (Phases 2-7)

```
lib/features/subscription/
├── models/
│   ├── subscription_product.dart
│   └── subscription_status.dart
├── services/
│   ├── firestore_payment_service.dart
│   └── subscription_storage_service.dart
├── repositories/
│   └── subscription_repository.dart
├── providers/
│   └── subscription_provider.dart
├── screens/
│   ├── subscription_screen.dart
│   ├── payment_method_screen.dart
│   ├── bank_transfer_screen.dart
│   └── receipt_upload_screen.dart
└── widgets/
    ├── subscription_card.dart
    ├── premium_feature_tile.dart
    ├── legal_disclaimer.dart
    ├── premium_badge.dart
    └── upgrade_cta.dart
```

---

## 🔑 Key Implementation Points

### 1. SubscriptionStatus Model

```dart
enum SubscriptionState {
  free,
  active,
  expired,
  pending,
  cancelled,
  error
}

@immutable
class SubscriptionStatus {
  final SubscriptionState state;
  final String? productId;
  final DateTime? expiryDate;
  final bool autoRenew;
  final String? paymentGateway;

  const SubscriptionStatus({
    required this.state,
    this.productId,
    this.expiryDate,
    this.autoRenew = false,
    this.paymentGateway,
  });

  bool get isActive =>
    state == SubscriptionState.active &&
    (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  bool get isExpired =>
    state == SubscriptionState.expired ||
    (expiryDate != null && expiryDate!.isBefore(DateTime.now()));

  SubscriptionStatus copyWith({...}) { ... }
}
```

### 2. Feature Gating Pattern

```dart
// In ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final subscription = ref.watch(subscriptionProvider);

  if (!subscription.status.isActive) {
    return UpgradeCTA(onTap: () => context.go('/subscription'));
  }

  return PremiumFeature();
}
```

### 3. Firestore Query Pattern

```dart
// In FirestorePaymentService
Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
  final doc = await db.collection('users').doc(userId).get();
  final data = doc.data();

  return SubscriptionStatus(
    state: _parseState(data?['subscription_status']),
    productId: data?['subscription_plan'],
    expiryDate: (data?['subscription_expiry_date'] as Timestamp?)?.toDate(),
    autoRenew: data?['auto_renew'] ?? false,
    paymentGateway: data?['payment_gateway'],
  );
}
```

---

## 📊 Implementation Timeline

| Phase | Task | Time | Status |
|-------|------|------|--------|
| 1 | Firestore setup + Security rules | 30 min | 📋 Ready |
| 1 | Cloud Functions (PayPal + 2Checkout) | 60 min | 📋 Ready |
| 1 | Test webhooks with ngrok | 30 min | 📋 Ready |
| 2 | FirestorePaymentService | 60 min | ⏳ Next |
| 2 | SubscriptionProvider (Riverpod) | 90 min | ⏳ Next |
| 3 | Localization (payment strings) | 30 min | ⏳ Next |
| 4 | UI Screens (7 screens) | 120 min | ⏳ Next |
| 5 | Feature gating in app | 60 min | ⏳ Next |
| 6 | Admin dashboard | 90 min | ⏳ Next |
| 7 | End-to-end testing | 120 min | ⏳ Next |

**Total Phase 1**: 2 hours
**Total Phases 1-7**: 9-10 hours (1-2 days intensive)

---

## ✅ Success Criteria for Phase 1

After completing Firestore setup + Cloud Functions:

- [ ] Firestore collections exist with correct schema
- [ ] Security rules deployed and tested
- [ ] PayPal webhook URL accessible and logs requests
- [ ] 2Checkout webhook URL accessible and logs requests
- [ ] User documents can be updated via Cloud Function
- [ ] Payment verification messages can be created
- [ ] Firestore rules allow only authorized access

---

## 🧪 Testing Phase 1 Setup

### Test Firestore Collections

```javascript
// In Firestore Console → Run Query
db.collection('users').limit(1).get()
db.collection('payments').limit(1).get()
db.collection('payment_verifications').limit(1).get()
```

### Test Cloud Functions Locally

```bash
# Install Firebase emulator
firebase emulators:start

# In another terminal, test webhook
curl -X POST http://localhost:5001/[project]/us-central1/paypalWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "BILLING.SUBSCRIPTION.CREATED",
    "resource": {
      "id": "sub_123",
      "custom_id": "user_test_123"
    }
  }'
```

### Deploy to Production

```bash
firebase deploy --only functions

# Get deployed function URLs
firebase functions:list

# Test with real webhook (use ngrok for testing)
ngrok http 5001
# Copy ngrok URL and add to PayPal/2Checkout webhook settings
```

---

## 🚀 After Phase 1

Once Firestore setup is complete:

1. **Phase 2**: Create Flutter services to interact with Firestore
2. **Phase 3**: Create Riverpod providers for state management
3. **Phase 4-5**: Build UI screens and add localization
4. **Phase 6-7**: Add feature gating and test end-to-end flows

---

## 📚 Full Documentation

- **Complete Plan**: `/docs/SESSION-2025-12-17-PAYMENT-SYSTEM-COMPLETE.md`
- **Pricing Model**: `/docs/PRICING_MODEL_FINAL.md`
- **Payment Summary**: `/docs/PAYMENT_SYSTEM_SUMMARY.md`
- **Architecture**: `/docs/01-ARCHITECTURE.md`

---

## 💡 Pro Tips

1. **Test webhooks locally first** using Firebase emulator before deploying
2. **Use ngrok** to expose local Cloud Functions to PayPal/2Checkout for testing
3. **Document webhook URLs** when you get them (they're long!)
4. **Set up Cloud Function monitoring** in Firebase Console to debug issues
5. **Use custom claims** for admin verification (set `is_admin: true` on admin users)

---

**Last Updated**: December 17, 2025
**Version**: 1.0
**Status**: Ready for Phase 1 Firebase implementation

