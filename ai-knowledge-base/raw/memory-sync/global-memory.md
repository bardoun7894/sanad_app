---
title: Pi Memory — Global
type: source
sync_origin: pi-memory://global
source: ~/.pi/memory/GLOBAL.md
---

# Pi Memory — Global

Agent behavior + environment notes, all projects.

- OpenCode Go can be installed as a Pi provider via `pi install npm:pi-opencode-bridge` — registers Go models from `~/.cache/opencode/models.json` and routes via Pi's OpenAI-compatible handler to `https://opencode.ai/zen/go/v1`; requires Go subscription key set via `/opencode-go-key` command.
- Pi stack 2026-06-26: base=@tmustier/pi-agent-teams + @tmustier UI. github.com/h4ni0/pi [filtered: keeps memory/subagents/image-gen/workflow/ui/code-state/side-chat; drops firecrawl-web.ts]. Custom: searxng-web.ts (SearXNG @ 127.0.0.1:8888, auto-starts), warp-image-paste.ts, workflow-enforcement.ts. Add-ons: pi-opencode-bridge, pi-lens, @ayulab/pi-rewind. Removed pi-subagents+pi-extensions (conflicted h4ni0/pi). `memory-kb-sync` mirrors ~/.pi/memory → ai-knowledge-base/raw/memory-sync/.
