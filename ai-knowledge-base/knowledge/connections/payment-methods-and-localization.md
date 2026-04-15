---
name: "Connection: Payment Methods and Localization"
description: Bank transfer details driven by locale files — pattern of externalizing payment configuration into the i18n system
type: connection
connects:
  - "concepts/bank-transfer-localization"
  - "concepts/payment-system"
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# Connection: Payment Methods and Localization

## The Connection

The Sanad App's bank transfer payment method bridges the payment system and the localization (i18n) system. Bank account details — which are traditionally treated as backend configuration — are stored in the same locale files (`app_strings.dart`, `app_strings_en.dart`, `app_strings_fr.dart`) that handle UI text translations.

## Key Insight

By storing bank details in locale files rather than in a backend config or environment variables, the app gains the ability to show **different bank accounts for different locales** without any conditional logic in Dart code. An Arabic-speaking user could see a UAE bank account, while a French-speaking user sees a European one. This is a non-obvious benefit of what initially looked like a simple "move hardcoded strings to locale files" refactoring. The i18n system becomes a lightweight configuration layer for payment routing.

## Evidence

During the 2026-04-13 session, bank details were moved from hardcoded values in `BankTransferScreen` into the three locale files. The fields (`bankAccountName`, `bankAccountNumber`, `bankSwiftCode`, `bankIban`, etc.) use `YOUR_*` placeholders. This was framed as a maintenance improvement (avoiding code changes for bank detail updates), but the locale-per-account capability is an emergent property of the chosen architecture.

No other payment method (Google Pay, Apple Pay, PayPal WebView) uses the locale system for configuration — those rely on JSON profile files or service-level credentials. Bank transfer is unique because it surfaces raw account details to the user, making it inherently a display concern rather than a backend API concern.

## Related Concepts

- [[concepts/payment-system]] — The parent architecture; bank transfer is the only method using locale-based configuration
- [[concepts/bank-transfer-localization]] — Detailed article on the locale file pattern and dynamic reference codes
- [[concepts/paypal-webview-flow]] — Contrasting approach: automated payment via WebView vs. manual transfer with locale-driven details
