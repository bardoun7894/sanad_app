---
name: Pi Memory — Global (mirror)
description: Mirror of the machine-wide Pi agent memory; agent tooling and environment notes that apply to every project, not to Sanad specifically
type: source
sources: [raw/memory-sync/global-memory.md]
created: "2026-07-29"
updated: "2026-07-29"
---
# Pi Memory — Global (mirror)

## Summary

A mirror of `~/.pi/memory/GLOBAL.md`, synced into the KB by the `memory-kb-sync` job. It records agent tooling and environment configuration that applies across every project on this machine — not knowledge about the Sanad app. It is captured here so the KB reflects the environment the work was done in.

> **Mirror, not an original.** The upstream file carries `sync_origin: pi-memory://global`. Edit `~/.pi/memory/GLOBAL.md` and let the sync run; edits made here are overwritten.

## Key points

- OpenCode Go can be installed as a Pi provider with `pi install npm:pi-opencode-bridge`. It registers Go models from `~/.cache/opencode/models.json` and routes through Pi's OpenAI-compatible handler to `https://opencode.ai/zen/go/v1`. It requires a Go subscription key, set via the `/opencode-go-key` command.
- Pi stack as of 2026-06-26: base is `@tmustier/pi-agent-teams` plus the `@tmustier` UI, from `github.com/h4ni0/pi`, filtered to keep memory, subagents, image-gen, workflow, UI, code-state and side-chat while dropping `firecrawl-web.ts`.
- Custom extensions: `searxng-web.ts` (SearXNG on `127.0.0.1:8888`, auto-starting), `warp-image-paste.ts`, and `workflow-enforcement.ts`.
- Add-ons: `pi-opencode-bridge`, `pi-lens`, `@ayulab/pi-rewind`.
- `pi-subagents` and `pi-extensions` were removed because they conflicted with `h4ni0/pi`.
- `memory-kb-sync` mirrors `~/.pi/memory` into `ai-knowledge-base/raw/memory-sync/`, which is how this document arrives in the KB.

## Scope note

Nothing here is Sanad-specific. It is listed in the index as environment context so that tooling decisions recorded in other articles have somewhere to point.

## See also

- [[sources/therapist-assignment-review]] — produced by one of the CLI reviewers this stack configures
- [[sources/freemius-3ds-white-screen]] — produced by the Kimi CLI in the same stack
