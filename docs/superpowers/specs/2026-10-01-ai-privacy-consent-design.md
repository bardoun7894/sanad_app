# AI privacy consent for the initial App Store release

Approved by the user on October 1, 2026: retain AI with explicit consent, and correct the app/site privacy descriptions of AI processing, authorized staff access, and crisis alerts.

Before the first transfer to Google Gemini, explain that chat messages/history and relevant profile and health context are sent to Google for AI responses/reports. Explain that safety screening can alert authorized Sanad staff. Offer Agree and Not now; declining must leave person-to-person therapist chat usable. Consent is scoped to the signed-in account and disclosure version, not the device or a different signed-in user.

Use the disclosure version `2026-10-01`. A callable `setAiPrivacyConsent` accepts `{accepted: boolean, version: '2026-10-01'}` and writes `users/{uid}.ai_privacy_consent = {accepted, version, updated_at: serverTimestamp}`. Require authentication, normalize server time, and reject unknown versions. Clients cannot write this field directly. Reading consent must not itself call Gemini.

Every Gemini entry point must check the relevant patient's current consent before any external request. Missing, declined, outdated or revoked consent fails closed. Check chat, crisis confirmation and generated reports; deterministic local/Firestore summaries do not require external-AI consent. Client checks improve the explanation; the server remains authoritative for server-mediated requests. A shared client consent service must cover any direct SDK call too.

Show a localized explanation in Arabic, English and French. Persist acceptance only after the server confirms it. Handle cancellation and write/read failures without making an AI request. Provide a way to revoke consent through the app's privacy controls. Do not block reading existing chat or messaging a human therapist.

Update live Firestore static-page content, the app fallback and the published website to identify Google Gemini and accurately describe service processors, authorized operational/support/safety access, and crisis escalation. Keep unrelated terms unchanged. Never assert that only a therapist can access cloud conversations or that AI data never leaves Sanad.

Verify rejected/accepted/outdated/revoked consent and account isolation, no external call before acceptance, persistence failure, localized UI and cancellation. Preserve subscription behavior. Upload a new build after verification; build 49 does not contain this consent change.
