---
name: Bank Transfer Localization
description: Bank transfer details moved to locale files with YOUR_* placeholders; dynamic reference codes per user per session
type: concept
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# Bank Transfer Localization

Bank transfer configuration in the Sanad App was refactored during the 2026-04-13 session to move all bank details from hardcoded UI strings into the locale system. Reference codes were also made dynamic, generating unique identifiers per user per session.

## Key Points

- Bank details (account name, number, SWIFT, IBAN) moved from hardcoded values in `BankTransferScreen` to locale files: `app_strings.dart`, `app_strings_en.dart`, `app_strings_fr.dart`.
- All bank fields use `YOUR_*` placeholders so real values can be filled without touching Dart code.
- Reference codes changed from a static hardcoded string to a dynamic pattern: `REF-{UID6}-{YYYYMMDD}-{SUFFIX}`, generated in `BankTransferScreen.initState()`.
- The WhatsApp deep link flow for sending transfer receipts remains unchanged.
- This pattern enables future localization of bank details per region without code changes.

## Details

Previously, bank account details were embedded directly in the `BankTransferScreen` widget's build method. This created two problems: changing bank details required a code change and app rebuild, and supporting different bank details for different locales (e.g., a UAE account for Arabic users, a European account for French users) was impossible without conditional logic in the widget.

The refactoring moved all six bank detail fields (`bankAccountName`, `bankAccountNumber`, `bankAccountHolder`, `bankSwiftCode`, `bankIban`, `supportWhatsAppNumber`) into the three locale files. Each field has a `YOUR_*` placeholder that the project owner fills in with real values. This approach cleanly separates configuration from code and leverages the existing i18n infrastructure.

The dynamic reference code (`REF-{UID6}-{YYYYMMDD}-{SUFFIX}`) replaces a previously hardcoded reference string. The UID6 segment is the first 6 characters of the Firebase user ID, YYYYMMDD is the current date, and SUFFIX provides uniqueness. This makes it possible to trace bank transfers back to specific users and sessions during manual admin approval — a significant improvement for the manual reconciliation workflow.

## Related Concepts

- [[concepts/payment-system]] — Bank transfer is one of five payment methods in the broader payment architecture
- [[concepts/paypal-webview-flow]] — Contrasting approach: automated card payment vs. manual bank transfer

## Sources

- [[daily/2026-04-13.md]] — Bank details moved to locale files with placeholders; reference code made dynamic with `REF-{UID6}-{YYYYMMDD}-{SUFFIX}` pattern
