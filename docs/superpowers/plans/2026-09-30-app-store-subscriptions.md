# App Store subscriptions implementation plan

Goal: sell the existing weekly, basic, premium and premium_vip plans through StoreKit on iOS, with Apple-verified entitlement dates and restore support.

Architecture: use Flutter's official in_app_purchase plugin (StoreKit 2), keep its purchase listener alive at app scope, and verify every transaction using Apple's server library and current subscription status API. Apple server notifications reconcile renewals, cancellation, expiration and refunds while the app is closed. Android and one-to-one session bookings keep their existing checkout.

- [ ] Backend: test invalid products, expiry/refunds, account binding, replay/idempotency and out-of-order updates; implement signed transaction verification, fresh status lookup and atomic Firestore updates.
- [ ] Client: test native product loading, pending/canceled/failed purchases, server rejection, verified completion, restore and account changes; implement an app-scoped purchase controller.
- [ ] UI: use native checkout for iOS subscriptions with localized prices, duration, renewal disclosure, Restore Purchases, Manage Subscriptions, privacy and terms links. Route subscription payment-method entry points to it; preserve therapy booking checkout.
- [ ] Configure four products in a single App Store Connect subscription group: com.sanadtherapy.app.weekly (one week), .basic (one month), .premium (one month), .premium_vip (one month). Use existing USD base prices 7.90, 19.90, 34.90 and 54.90 where Apple's price points allow; report any unavoidable price-point difference before setting it.
- [ ] Add Apple root certificates, server environment configuration and operational setup instructions. Never expose signing keys or receipts in logs or source.
- [ ] Run focused Flutter and Node tests, analyzer, formatting and iOS compilation; independent review fixes findings and reruns checks.

App: com.sanadtherapy.app, App Store ID 6817892036, HM5 Group team SMMX7CLH24. Server credentials, notification registration, Paid Apps Agreement, product metadata/review assets and real sandbox-device purchase remain external setup requirements; report concrete blockers rather than claiming a live payment test.
