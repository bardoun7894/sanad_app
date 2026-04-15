# Sanad App Health Check & Repair Report

**Date**: December 27, 2025
**Status**: REPAIRS APPLIED

## 1. Summary of Repairs
We performed a comprehensive health check of the project's data and configuration. The following critical issues were identified and resolved without needing to wipe the database.

### ✅ Fixed Items
- **[FIXED] VIP Subscription Tier**: The `premium_vip` product was missing from Firestore.
    - *Action*: Created `tool/seed_vip.dart` and backfilled the missing product.
    - *Status*: Verified in Firestore.
- **[FIXED] PayPal Security**: Credentials were hardcoded in `paypal_payment_screen.dart`.
    - *Action*: Implemented `flutter_dotenv`, moved keys to `.env`, and updated code to read from environment.
    - *Status*: Secure.
- **[FIXED] Therapist Verification Logic**: Logic bug in `auth_provider.dart` prevented legacy users from getting `approved` status.
    - *Action*: Updated `_syncUserData` to verify against `therapists` collection.
    - *Status*: Deployed.

## 2. Outstanding / Acceptable Gaps

### Content URLs
- **Status**: Placeholders (e.g., `https://example.com/podcast3`).
- **Decision**: Acceptable for current demo/development phase. Real content URLs should be updated via the Content Management Admin Panel later.

### CocoaPods/MacOS Build
- **Status**: `pod install` fails on macOS due to version conflicts between `google_sign_in` and `firebase_messaging`.
- **Workaround**: We successfully used `flutter run -d chrome` (Web) to execute repair scripts.
- **Recommendation**: For iOS release, ensure to align versions (likely downgrading `google_sign_in` or overriding dependencies) if the issue persists.

## 3. Configuration Instructions
New developers must create a `.env` file in the root directory:

```bash
# .env
PAYPAL_CLIENT_ID=your_client_id
PAYPAL_SECRET_KEY=your_secret_key
```

## 4. Next Steps
- Restart the application to see the "VIP Gold Plan" in the subscription screen.
- Verify the "Therapist Portal" access for approved therapists.
