# Knowledge Base Index

| Article | Summary | Type | Updated |
|---------|---------|------|---------|
| [[concepts/payment-system]] | Multi-gateway payments: Google Pay, Apple Pay, PayPal card, bank transfer. Config requirements, flow, known TODOs. | concept | 2026-04-13 |
| [[concepts/apple-pay-integration]] | Apple Pay screen built from scratch — merchant ID registration, domain verification, PayPal token flow | concept | 2026-04-13 |
| [[concepts/google-pay-paypal-gateway]] | Google Pay configured with PayPal as gateway in production mode — merchant ID requirement and token flow | concept | 2026-04-13 |
| [[concepts/bank-transfer-localization]] | Bank transfer details moved to locale files with YOUR_* placeholders; dynamic reference codes per user per session | concept | 2026-04-13 |
| [[concepts/paypal-webview-flow]] | Card and PayPal checkout via WebView — cancel URL detection fix, deep-link interception, dead code cleanup | concept | 2026-04-13 |
| [[connections/payment-methods-and-localization]] | Bank transfer bridges payment system and i18n — locale files double as payment config layer | connection | 2026-04-13 |
| [[sources/admin-chat-name-fix]] | Six-file fix chain resolving the "Unknown" user name bug in admin chat | source | 2026-06-25 |
| [[entities/mood-feed-screen]] | Admin dashboard mood feed with polarity-filtered entries and "Message" navigation | entity | 2026-06-25 |
| [[entities/admin-chat-detail-screen]] | Admin one-to-one chat detail with name resolution before send | entity | 2026-06-25 |
| [[entities/admin-chat-service]] | Admin-side Firestore chat service with name guard on write | entity | 2026-06-25 |
| [[entities/user-support-chat-service]] | User-side Firestore chat service — thread creation and message sending | entity | 2026-06-25 |
| [[entities/user-support-chat-provider]] | Riverpod StateNotifier for user support chat session state | entity | 2026-06-25 |
| [[concepts/admin-chat-display-name]] | Name resolution strategy for admin chat — avoid placeholder propagation | concept | 2026-06-25 |
| [[concepts/support-chat-thread]] | Firestore thread model — schema, creation, name/email lifecycle | concept | 2026-06-25 |
| [[sources/admin-chat-name-fix-2026-06-26]] | Follow-up pass on the admin chat placeholder-name bug — list card, broadcast write path, async resolution | source | 2026-07-29 |
| [[sources/freemius-3ds-white-screen]] | Android WebView drops window.open during 3DS because the plugin enables multiple windows without implementing onCreateWindow | source | 2026-07-29 |
| [[sources/therapist-assignment-review]] | Codex review of therapist assignment that timed out early; confirmed chat ID consistency, no P0/P1 found | source | 2026-07-29 |
| [[sources/pi-global-memory]] | Mirror of machine-wide Pi agent memory — tooling and environment, not Sanad knowledge | source | 2026-07-29 |
| [[concepts/webview-popup-handling]] | Why window.open silently disappears in Android WebViews and how it breaks payment step-ups | concept | 2026-07-29 |
| [[concepts/therapist-chat-id-convention]] | Patient–therapist threads keyed by composite {therapistId}_{userId}, derived at every call site | concept | 2026-07-29 |
| [[entities/payment-webview]] | Shared payment WebView widget carrying the multiple-window fix and stuck-load watchdog | entity | 2026-07-29 |
