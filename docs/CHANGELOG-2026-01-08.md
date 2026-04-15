# Changelog - 2026-01-08

## [Admin Panel Enhancement] - Subscription Management

### Added
- **Admin Subscription Management**: New functionality to manually assign and revoke subscription plans for users.
- **AdminUsersProvider**: Added `assignSubscription()` and `revokeSubscription()` methods.
  - `assignSubscription()`: Sets premium status, plan details, and start/end dates. Creates a payment record in Firestore for tracking.
  - `revokeSubscription()`: Reverts user to free status and records revocation details.
- **Users List Screen UI**: 
  - Implementation of "Grant Premium" and "Revoke Premium" dialogs in the user menu.
  - Support for selecting from all existing plans (Weekly, Basic, Premium, VIP).
  - Support for custom subscription durations (7d, 30d, 90d, 365d quick buttons or manual entry).
- **Firestore Integration**: Subscription data is persisted with fields for start/end dates, plan ID, and admin assignment tracking.

### Status
- Feature is **100% Functional** and integrated into the Admin Users management flow.
- Verified persistence in Firestore and local state updates via Riverpod.
