# Sanad App - Cloud Functions

Backend infrastructure for Sanad App using Firebase Cloud Functions.

---

## Payment System (Client-Side)

**Note**: Payment webhooks have been **removed**. The app now uses **client-side PayPal integration** via Dart/Flutter.

### How It Works

```
User selects PayPal payment
  ↓
App creates payment via PayPal REST API (client-side)
  ↓
WebView opens PayPal approval URL
  ↓
User completes payment in PayPal
  ↓
PayPal redirects back with paymentId + payerId
  ↓
App confirms payment and updates Firestore directly
  ↓
Subscription activated
```

### Implementation Files

- `lib/features/subscription/screens/paypal_payment_screen.dart` - PayPal payment UI
- `lib/features/subscription/screens/paypal_checkout_mobile.dart` - WebView checkout
- `lib/features/subscription/providers/subscription_provider.dart` - State management

### Environment Variables

Create `.env` file with:
```
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_SECRET_KEY=your_secret_key
PAYPAL_SANDBOX=true  # Set to false for production
```

---

## Cloud Functions (Main)

All Cloud Functions are now centralized in `/functions/index.js`.

### Deployed Functions

| Function | Type | Purpose |
|----------|------|---------|
| `seedDb` | HTTP | Database seeding |
| `onBookingCreated` | Firestore Trigger | Notify therapist of new booking |
| `onBookingStatusChanged` | Firestore Trigger | Notify client of status changes |
| `onTherapistChatMessage` | Firestore Trigger | Notify recipient of new message |
| `onTherapistApprovalChanged` | Firestore Trigger | Notify therapist of approval |
| `onSupportChatMessage` | Firestore Trigger | Notify admins of support messages |
| `onUserRoleChanged` | Firestore Trigger | Sync custom claims on role change |
| `onTherapistStatusChanged` | Firestore Trigger | Sync therapist approval status |
| `setAdminClaim` | Callable | Grant/revoke admin role |
| `setTherapistClaim` | Callable | Grant/revoke therapist role |

### Deployment

```bash
cd functions
npm install
firebase deploy --only functions
```

---

## Alternative Payment Methods

### Bank Transfer
- User uploads receipt via `ReceiptUploadScreen`
- Admin reviews in `VerificationListScreen`
- Manual approval updates subscription

---

## Related Documentation

- **Payment System**: See `docs/PAYMENT_SYSTEM_SUMMARY.md`
- **Features Status**: See `docs/FEATURES-STATUS.md`
- **Firestore Setup**: See `docs/FIRESTORE-SETUP.md`

---

**Last Updated**: December 29, 2025
**Version**: 2.0
**Status**: Client-Side PayPal Implementation
