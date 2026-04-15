# Implementation Plan: Unified Multi-Agent Workflows

**Branch**: `003-antigravity-templates` | **Date**: 2026-01-12 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-antigravity-templates/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature enables a unified workflow system that works across both Antigravity IDE and Claude Code agents. The primary requirement is to provide the 9 core Speckit workflows (specify, plan, tasks, implement, clarify, analyze, constitution, checklist, taskstoissues) as Markdown files with appropriate frontmatter that can be consumed by both AI agent systems. The technical approach involves creating workflow definitions in `.agent/workflows/` for Antigravity and `.claude/commands/` for Claude, ensuring format compatibility and cross-agent accessibility.

## Technical Context

**Language/Version**: Markdown (workflow definitions), Shell/Bash (automation scripts)
**Primary Dependencies**: Antigravity IDE YAML frontmatter spec, Claude Code skill format
**Storage**: File-based (`.agent/workflows/` for Antigravity, `.claude/commands/` for Claude)
**Testing**: Manual workflow execution validation, format parsing tests
**Target Platform**: Cross-platform (macOS, Linux, Windows via Antigravity IDE + Claude Code CLI)
**Project Type**: Documentation/Template project (workflow definitions, not runtime code)
**Performance Goals**: Instant workflow loading (<100ms), negligible memory footprint
**Constraints**: Must maintain dual compatibility (Antigravity YAML + Claude markdown), preserve existing project structure
**Scale/Scope**: 9 core workflows, 2 agent systems (Antigravity + Claude), ~50 workflow files total (base + variations)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with all principles from `.specify/memory/constitution.md`:

- [x] **Prime Directive**: Does this feature maintain or add to existing functionality without breaking anything?
  - ✅ YES: This feature adds new workflow capabilities without modifying existing code. It's purely additive (creates files in `.agent/` and `.claude/` directories).

- [x] **Documentation**: Will docs be updated (`FEATURES-STATUS.md`, `CHANGELOG-*.md`)?
  - ✅ YES: Will update CHANGELOG-2026-01-12.md with workflow additions.

- [x] **Localization**: All text localized via `LanguageProvider`? RTL support for Arabic?
  - ⚠️ N/A: Workflows are developer-facing documentation in English. Not user-facing UI. No localization required.

- [x] **Security**: Firebase rules compliant? Authentication checks in place?
  - ✅ N/A: No database operations. File-based workflow definitions only.

- [x] **State Management**: Using Riverpod providers correctly?
  - ✅ N/A: No runtime state management. Static workflow files.

- [x] **Routing**: Named routes in `app_router.dart`?
  - ✅ N/A: No UI routing. Developer workflow commands only.

- [x] **Testing**: Feature manually tested? Critical paths have integration tests?
  - ✅ YES: Will manually test each workflow execution in both Antigravity and Claude.

- [x] **Performance**: App startup <3s? 60 FPS maintained? Images optimized? Bundle size monitored?
  - ✅ N/A: Does not affect app runtime performance. Workflows are dev-time tools.

- [x] **Quality Gates**: `flutter analyze` passes? Tests pass? Localization tested?
  - ✅ YES: No Dart code changes, so `flutter analyze` unaffected. Workflow syntax will be validated.

- [x] **Versioning**: Version bumped correctly (SemVer)? Changelog updated?
  - ✅ YES: Will document in CHANGELOG. No app version bump needed (dev tooling, not user features).

- [x] **Error Handling**: Async operations have error handling? Errors logged appropriately?
  - ✅ N/A: Workflows are declarative Markdown. Error handling is agent-specific.

**Violations Justification** (if any):
- Localization N/A: Workflows are English-only developer documentation, not user-facing UI. Constitution principle III applies to app UI strings, not internal developer tooling.

## Project Structure

### Documentation (this feature)

```text
specs/003-antigravity-templates/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── antigravity-workflow-schema.yaml
│   └── claude-skill-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Selected Structure: Dual-location template files

.agent/
└── workflows/
    ├── speckit.specify.md
    ├── speckit.plan.md
    ├── speckit.tasks.md
    ├── speckit.implement.md
    ├── speckit.clarify.md
    ├── speckit.analyze.md
    ├── speckit.constitution.md
    ├── speckit.checklist.md
    └── speckit.taskstoissues.md

.claude/
└── commands/
    ├── speckit.specify.md
    ├── speckit.plan.md
    ├── speckit.tasks.md
    ├── speckit.implement.md
    ├── speckit.clarify.md
    ├── speckit.analyze.md
    ├── speckit.constitution.md
    ├── speckit.checklist.md
    └── speckit.taskstoissues.md

.specify/
├── memory/
│   ├── constitution.md  (already exists)
│   └── project-context.md (already exists)
├── scripts/
│   └── bash/
│       ├── setup-plan.sh (to be created)
│       ├── setup-tasks.sh (to be created)
│       └── check-prerequisites.sh (to be created)
└── templates/
    ├── plan-template.md (already exists)
    ├── tasks-template.md (already exists)
    └── spec-template.md (already exists)
```

**Structure Decision**: Dual-location strategy selected to support both agent systems simultaneously. Antigravity IDE reads from `.agent/workflows/` (YAML frontmatter + Markdown), while Claude Code reads from `.claude/commands/` (simpler Markdown format). This allows each agent to use its native format without cross-compatibility issues. Shared templates remain in `.specify/templates/` for source-of-truth maintenance.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Localization N/A | Workflows are English-only developer docs | Translating workflow instructions would create maintenance burden without user benefit (developers work in English) |

---

## Phase 0: Research & Discovery (NEEDS CLARIFICATION Resolution)

**Status**: Ready to execute
**Output**: `research.md`

### Research Tasks

1. **Antigravity Workflow Format Specification**
   - Task: Document the exact YAML frontmatter schema required by Antigravity IDE
   - Why: Spec says "YAML frontmatter format" but doesn't define structure
   - Deliverable: Schema definition with required/optional fields

2. **Claude Code Skill Format Requirements**
   - Task: Document Claude Code's expected skill file format
   - Why: Spec says "Claude agent compatibility" but format undefined
   - Deliverable: Format specification with examples

3. **Existing Workflow Inventory**
   - Task: Audit current `.claude/commands/` directory for existing workflows
   - Why: Need to understand what already exists before adding 9 new workflows
   - Deliverable: List of existing files and their purposes

4. **Cross-Agent Testing Strategy**
   - Task: Define how to validate workflows work in both agents
   - Why: Success criteria require end-to-end execution validation
   - Deliverable: Test plan with validation steps

5. **Script Dependencies & Prerequisites**
   - Task: Identify required tooling (bash version, utilities) for automation scripts
   - Why: Spec mentions "PowerShell" as potential dependency issue
   - Deliverable: Minimum requirements list

---

## Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete
**Status**: Pending Phase 0
**Output**: `data-model.md`, `contracts/`, `quickstart.md`

### Design Artifacts

1. **data-model.md**: Workflow File Schema
   - Entity: `WorkflowDefinition`
     - Fields: `name`, `description`, `arguments`, `steps`, `prerequisites`, `outputs`
   - Entity: `AntigravityFrontmatter`
     - Fields: `title`, `description`, `tags`, `version`
   - Entity: `ClaudeSkillMetadata`
     - Fields: `skill_name`, `description`, `usage_pattern`

2. **contracts/antigravity-workflow-schema.yaml**: OpenAPI-style schema for Antigravity format
3. **contracts/claude-skill-schema.md**: Specification for Claude skill format
4. **quickstart.md**: Developer onboarding guide for using workflows in both agents

---

## Phase 2: Implementation Planning (Deferred to /speckit.tasks)

**Note**: This phase is handled by the `/speckit.tasks` command, not by `/speckit.plan`.

---

## Next Steps

1. Execute Phase 0: Run research tasks and generate `research.md`
2. Execute Phase 1: Generate data model and contracts
3. Run `/speckit.tasks` to create `tasks.md` with implementation breakdown
4. Run `/speckit.implement` to execute tasks
