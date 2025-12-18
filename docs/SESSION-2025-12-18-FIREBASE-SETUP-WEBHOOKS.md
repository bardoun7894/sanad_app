# Session: Firebase Setup and Webhook Implementation

**Date**: December 18, 2025
**Status**: Implementation Complete (Awaiting Plan Upgrade)

---

## Overview

In this session, we connected the Sanad app to a new Firebase project and implemented the Cloud Functions for PayPal and 2Checkout webhooks.

## Tasks Accomplished

### 1. Firebase Project Setup
- Created new Firebase project: `sanad-app-beldify`
- Initialized local project with Firebase CLI (`firebase.json`, `.firebaserc`)
- Registered Android app: `com.sanad.sanad_app`
- Registered iOS app: `com.sanad.sanadApp`
- Downloaded and placed configuration files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

### 2. Firestore Configuration
- Created `firestore.rules` with initial security:
  ```javascript
  allow read, write: if request.auth != null;
  ```
- Deployed Firestore rules to the cloud.

### 3. Cloud Functions (Webhooks)
- Created a standard `functions/` directory for Firebase Functions.
- Implemented `paypalWebhook` and `checkoutWebhook` in `functions/index.js`.
- Handlers manage:
  - Subscription creation/activation
  - Renewals
  - Cancellations/Expirations
  - Payment failures/Suspensions
  - Automated push notifications via FCM
- Configured `firebase.json` for easy deployment.

## Technical Details

### Webhook Endpoints
- **PayPal**: `https://us-central1-sanad-app-beldify.cloudfunctions.net/paypalWebhook`
- **2Checkout**: `https://us-central1-sanad-app-beldify.cloudfunctions.net/checkoutWebhook`

### Stored Data
When webhooks trigger, they update the following Firestore fields in `users/{uid}`:
- `subscription_status`: "active" | "expired" | "pending" | "cancelled"
- `subscription_expiry_date`: Extended by 30 days on success
- `payment_gateway`: "paypal" | "2checkout"
- `fcm_tokens`: Used for push notifications

## Next Steps

1. **Upgrade to Blaze Plan**: Required to deploy Cloud Functions.
2. **Deploy Functions**: Run `firebase deploy --only functions`.
3. **Connect Gateways**:
   - Add webhook URL to PayPal Developer Dashboard.
   - Add webhook URL to 2Checkout Merchant Panel.
4. **App Integration**:
   - Ensure the app uses `Firebase.initializeApp()` with the new config.
   - Test the subscription flow in sandbox mode.

---

**Last Updated**: December 18, 2025
