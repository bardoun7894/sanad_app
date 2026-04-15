# Sanad App - Claude Code Instructions

## Second Brain

All project knowledge — architecture decisions, error patterns, dependency choices, discussions, and context — lives in the **NotebookLM notebook**. This file does NOT store knowledge. The notebook is the single source of truth.

### NotebookLM Access

- **Notebook ID**: `c7d02db3-9523-4ab0-ad7c-3155e0027bcd`
- **URL**: https://notebooklm.google.com/notebook/c7d02db3-9523-4ab0-ad7c-3155e0027bcd
- **Title**: Sanad App - Source of Truth

### How to Use NotebookLM as Source of Truth

**Query the notebook** before making architectural decisions or when you need project context:

```
notebook_query(notebook_id="c7d02db3-9523-4ab0-ad7c-3155e0027bcd", query="your question here")
```

**Add new sources** when new documentation is created:

```
source_add(notebook_id="c7d02db3-9523-4ab0-ad7c-3155e0027bcd", source_type="file", file_path="/path/to/doc.md")
```

**Generate artifacts** (podcasts, reports, quizzes, flashcards) from project knowledge:

```
studio_create(notebook_id="c7d02db3-9523-4ab0-ad7c-3155e0027bcd", artifact_type="report", confirm=True)
```

### Current Sources (12 docs)

| Source                           | Content                                            |
| -------------------------------- | -------------------------------------------------- |
| `00-PROJECT-OVERVIEW.md`         | Project scope, features, tech stack                |
| `01-ARCHITECTURE.md`             | Layered architecture, Riverpod patterns, data flow |
| `02-THIRD-PARTY-INTEGRATIONS.md` | Agora, Firebase, PayPal, 2Checkout                 |
| `03-PAYMENT-SYSTEM.md`           | Pricing tiers, dual gateway, feature gating        |
| `FEATURES-STATUS.md`             | Audited feature status (~94% complete)             |
| `PRODUCTION-READINESS-REPORT.md` | 95% production ready                               |
| `IMPLEMENTATION-ROADMAP.md`      | Full roadmap, phases, revenue projections          |
| `FIRESTORE-COLLECTIONS.md`       | Complete Firestore schema (20+ collections)        |
| `data-contract.md`               | Canonical field names, types, enums                |
| `REMAINING-WORK.md`              | 20 remaining tasks with priority phases            |
| `CHANGELOG-2026-02.md`           | Laravel admin dashboard (v1.0.0)                   |
| `NEXT-FEATURES-PLAN.md`          | Crisis detection, Hybrid AI+Therapy, Gamification  |

### When to Query the Notebook

- Before implementing a new feature — check existing patterns and decisions
- When unsure about Firestore schema or field names — query data-contract
- When debugging — check known issues in REMAINING-WORK
- Before choosing a library or approach — check architecture decisions
- When onboarding — get a full project summary

### When to Add Sources

- After creating new documentation in `docs/`
- After major architectural changes
- After adding new features with significant design decisions
- After resolving complex bugs worth documenting
