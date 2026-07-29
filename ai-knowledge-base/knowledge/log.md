# Build Log

Append-only log of compile and ingest operations.

## [2026-04-13T23:15:29+01:00] compile | 2026-04-13.md
- Source: daily/2026-04-13.md
- Articles created: [[concepts/apple-pay-integration]], [[concepts/google-pay-paypal-gateway]], [[concepts/bank-transfer-localization]], [[concepts/paypal-webview-flow]], [[connections/payment-methods-and-localization]]
- Articles updated: [[concepts/payment-system]] (added cross-links, 2026-04-13 changes section, Related Concepts, Sources; updated frontmatter to unified schema)

## [2026-06-25T16:00:00+01:00] ingest | raw/admin-chat-name-fix-2026-06-25.md
- Source: raw/admin-chat-name-fix-2026-06-25.md
- Source page: [[sources/admin-chat-name-fix]]
- Concepts created: [[concepts/admin-chat-display-name]], [[concepts/support-chat-thread]]
- Concepts updated: none
- Entities created: [[entities/mood-feed-screen]], [[entities/admin-chat-detail-screen]], [[entities/admin-chat-service]], [[entities/user-support-chat-service]], [[entities/user-support-chat-provider]]
- Entities updated: none
- Contradictions with existing articles: none

## [2026-07-29T00:55:00+01:00] ingest | raw/admin-chat-name-fix-2026-06-26.md
- Source: raw/admin-chat-name-fix-2026-06-26.md
- Source page: [[sources/admin-chat-name-fix-2026-06-26]]
- Concepts created: none
- Concepts updated: [[concepts/admin-chat-display-name]] (display-layer fallback, async list resolution, closing the broadcast write path), [[concepts/support-chat-thread]] (broadcast path, reading the cached name)
- Entities created: none
- Entities updated: [[entities/admin-chat-service]] (resolveRealName, resolveDisplayNameForThread, broadcast fix), [[entities/admin-chat-detail-screen]] (FutureBuilder header, placeholder repair on send)
- Contradictions with existing articles: none — extends the 2026-06-25 pass rather than revising it

## [2026-07-29T00:55:00+01:00] ingest | raw/kimi/2026-07-17-freemius-3ds-white-screen.md
- Source: raw/kimi/2026-07-17-freemius-3ds-white-screen.md
- Source page: [[sources/freemius-3ds-white-screen]]
- Concepts created: [[concepts/webview-popup-handling]]
- Concepts updated: [[concepts/paypal-webview-flow]] (cross-linked the popup mechanism and shared widget)
- Entities created: [[entities/payment-webview]]
- Entities updated: none
- Contradictions with existing articles: none
- Note: raw file is an unedited model reasoning stream (mojibake, mid-word line wraps, self-corrections, ends mid-sentence). Only conclusions were extracted, each verified against lib/core/widgets/payment_webview.dart rather than trusted from the transcript.

## [2026-07-29T00:55:00+01:00] ingest | raw/codex/2026-05-02-therapist-assignment-review.md
- Source: raw/codex/2026-05-02-therapist-assignment-review.md
- Source page: [[sources/therapist-assignment-review]]
- Concepts created: [[concepts/therapist-chat-id-convention]]
- Concepts updated: none
- Entities created: none
- Entities updated: none
- Contradictions with existing articles: none
- Note: the review timed out at 120s mid-analysis. Absence of findings is not evidence of correctness for the areas it never reached.

## [2026-07-29T00:55:00+01:00] ingest | raw/memory-sync/global-memory.md
- Source: raw/memory-sync/global-memory.md
- Source page: [[sources/pi-global-memory]]
- Concepts created: none
- Concepts updated: none
- Entities created: none
- Entities updated: none
- Contradictions with existing articles: none
- Note: a mirror of ~/.pi/memory/GLOBAL.md (sync_origin: pi-memory://global), not Sanad knowledge. Edits belong upstream; the sync overwrites this copy.
