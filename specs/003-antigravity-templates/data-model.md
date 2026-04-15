# Data Model: Unified Multi-Agent Workflows

**Feature**: 003-antigravity-templates
**Date**: 2026-01-12
**Phase**: 1 (Design & Contracts)
**Status**: Complete

---

## Overview

This document defines the data structures for the Unified Multi-Agent Workflow system. The system uses Markdown files with YAML frontmatter to define AI agent workflows that are compatible with both Antigravity IDE and Claude Code.

---

## Entity: WorkflowDefinition

**Description**: A complete workflow file consisting of YAML frontmatter and Markdown body.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `frontmatter` | `WorkflowFrontmatter` | Yes | YAML metadata at top of file |
| `body` | `string` (Markdown) | Yes | Workflow instructions in Markdown format |
| `file_path` | `string` | Yes | Location of workflow file (e.g., `.agent/workflows/speckit.plan.md`) |
| `agent_system` | `enum['antigravity', 'claude']` | Yes | Target agent system |

### Validation Rules
- File must start with YAML frontmatter delimited by `---`
- Body must be valid Markdown
- File name must follow pattern: `[namespace].[workflow-name].md`
- Namespace examples: `speckit`, `sanad`, project-specific
- Workflow name must be kebab-case (lowercase with hyphens)

### Example Structure

```markdown
---
description: Execute the implementation planning workflow
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
---

## User Input

$ARGUMENTS

[Rest of Markdown body...]
```

---

## Entity: WorkflowFrontmatter

**Description**: YAML metadata block at the beginning of a workflow file.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | `string` | Yes | Single-line description of workflow purpose |
| `handoffs` | `HandoffConfiguration[]` | No | Array of handoff actions to other workflows |

### Validation Rules
- `description` must be a single line (no newlines)
- `description` should be concise (recommended <100 characters)
- `handoffs` array can be empty or omitted

### Example

```yaml
---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
handoffs:
  - label: Implement Tasks
    agent: speckit.implement
    prompt: Execute the implementation plan
    send: true
  - label: Analyze Spec
    agent: speckit.analyze
    prompt: Check for inconsistencies
    send: false
---
```

---

## Entity: HandoffConfiguration

**Description**: Definition of a handoff action that navigates from one workflow to another.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `label` | `string` | Yes | Human-readable display text for the handoff button/link |
| `agent` | `string` | Yes | Target workflow filename without `.md` extension |
| `prompt` | `string` | Yes | Prompt text sent to the target workflow |
| `send` | `boolean` | No | Whether handoff is auto-triggered (default: `false`) |

### Validation Rules
- `label` must be non-empty
- `agent` must reference an existing workflow file (e.g., `speckit.tasks` → `speckit.tasks.md`)
- `prompt` must be non-empty
- `send` defaults to `false` if omitted

### Relationships
- **Many-to-One**: Multiple handoffs can target the same agent
- **Directed Graph**: Handoffs form a directed graph of workflow transitions

### Example

```yaml
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Review Constitution
    agent: speckit.constitution
    prompt: View current constitution
    send: false
```

---

## Entity: ScriptInvocation

**Description**: A command to run an automation script from within a workflow.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `script_path` | `string` | Yes | Relative path to script from repo root |
| `arguments` | `string[]` | No | Array of command-line arguments |
| `output_format` | `enum['json', 'text']` | No | Expected output format (default: `text`) |
| `required_keys` | `string[]` | Conditional | Required JSON keys if `output_format=json` |

### Validation Rules
- `script_path` must start with `.specify/scripts/bash/` (Claude) or `.specify/scripts/powershell/` (Antigravity)
- `script_path` must reference an existing file
- If `output_format=json`, script must output valid JSON
- `required_keys` must be non-empty if `output_format=json`

### Script Output Schema (JSON)

All scripts that output JSON must follow this schema:

```json
{
  "status": "success" | "error",
  "message": "Human-readable status message",
  "data": {
    // Script-specific data fields
  }
}
```

### Example (Bash - Claude)

```bash
# Workflow instruction:
Run `.specify/scripts/bash/setup-plan.sh --json "specs/003-antigravity-templates"`

# Expected output:
{
  "status": "success",
  "message": "Feature directory initialized",
  "data": {
    "FEATURE_SPEC": "/Users/mac/sanad_app/specs/003-antigravity-templates/spec.md",
    "IMPL_PLAN": "/Users/mac/sanad_app/specs/003-antigravity-templates/plan.md",
    "SPECS_DIR": "/Users/mac/sanad_app/specs",
    "BRANCH": "003-antigravity-templates"
  }
}
```

### Example (PowerShell - Antigravity)

```powershell
# Workflow instruction:
Run `.specify/scripts/powershell/setup-plan.ps1 -Json "specs/003-antigravity-templates"`

# Expected output: (same JSON format as bash)
```

---

## Entity: ArgumentSubstitution

**Description**: Variable substitution mechanism in workflow bodies.

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `variable_name` | `string` | Yes | Name of the variable (e.g., `ARGUMENTS`) |
| `substitution_pattern` | `string` | Yes | Pattern in markdown (e.g., `$ARGUMENTS`) |
| `value_source` | `enum['user_input', 'script_output', 'handoff_prompt']` | Yes | Where the value comes from |

### Predefined Variables

| Variable | Pattern | Source | Description |
|----------|---------|--------|-------------|
| `ARGUMENTS` | `$ARGUMENTS` | User input | Arguments passed to workflow by user |
| `FEATURE_SPEC` | `$FEATURE_SPEC` | Script output | Path to spec.md from setup scripts |
| `IMPL_PLAN` | `$IMPL_PLAN` | Script output | Path to plan.md from setup scripts |
| `TASKS_FILE` | `$TASKS_FILE` | Script output | Path to tasks.md from setup scripts |
| `BRANCH` | `$BRANCH` | Script output | Git branch name for feature |

### Example

```markdown
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json "$ARGUMENTS"`
```

When user invokes: `/speckit.plan specs/003-antigravity-templates`

Result:
- `$ARGUMENTS` → `specs/003-antigravity-templates`
- Script receives: `setup-plan.sh --json "specs/003-antigravity-templates"`
- Script outputs: JSON with `FEATURE_SPEC`, `IMPL_PLAN`, etc.

---

## State Transitions

Workflows form a directed graph with the following common paths:

```
┌─────────────────┐
│ speckit.specify │ (Create feature spec)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  speckit.plan   │ (Create implementation plan)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  speckit.tasks  │ (Break plan into tasks)
└────────┬────────┘
         │
         ├────────────┐
         │            ▼
         │     ┌──────────────────┐
         │     │ speckit.analyze  │ (Validate consistency)
         │     └──────────────────┘
         │
         ▼
┌────────────────────┐
│ speckit.implement  │ (Execute tasks)
└────────────────────┘
```

### Parallel Paths

At any point, users can invoke:
- `speckit.clarify` - Ask clarification questions
- `speckit.constitution` - View project constitution
- `speckit.checklist` - Generate verification checklist
- `speckit.taskstoissues` - Convert tasks to GitHub issues

---

## File System Schema

### Directory Structure

```text
# Antigravity IDE Location
.agent/
└── workflows/
    ├── [namespace].[workflow-name].md  (e.g., speckit.plan.md)
    └── [namespace].[workflow-name].md

# Claude Code Location
.claude/
└── commands/
    ├── [namespace].[workflow-name].md  (e.g., speckit.plan.md)
    └── [namespace].[workflow-name].md

# Supporting Scripts
.specify/
├── scripts/
│   ├── bash/              (Unix-like systems - Claude)
│   │   ├── setup-plan.sh
│   │   ├── setup-tasks.sh
│   │   ├── setup-specify.sh
│   │   ├── check-prerequisites.sh
│   │   └── update-agent-context.sh
│   └── powershell/        (Windows/cross-platform - Antigravity)
│       ├── setup-plan.ps1
│       ├── setup-tasks.ps1
│       ├── setup-specify.ps1
│       ├── check-prerequisites.ps1
│       └── update-agent-context.ps1
└── templates/
    ├── spec-template.md
    ├── plan-template.md
    └── tasks-template.md
```

### Naming Conventions

- **Workflow files**: `[namespace].[workflow-name].md`
  - Namespace: lowercase, single word (e.g., `speckit`, `sanad`)
  - Workflow name: lowercase, hyphenated (e.g., `plan`, `tasks-to-issues`)
- **Script files**: `[action]-[noun].[ext]`
  - Action: verb (e.g., `setup`, `check`, `update`)
  - Noun: object (e.g., `plan`, `tasks`, `prerequisites`)
  - Extension: `.sh` (bash) or `.ps1` (PowerShell)

---

## Integration Points

### Antigravity IDE
- Reads workflows from `.agent/workflows/`
- Parses YAML frontmatter for `description` and `handoffs`
- Displays handoffs as clickable actions
- Invokes PowerShell scripts via `.specify/scripts/powershell/`

### Claude Code
- Reads workflows from `.claude/commands/`
- Parses YAML frontmatter (same schema as Antigravity)
- Executes workflows when user types `/[workflow-name]`
- Invokes bash scripts via `.specify/scripts/bash/`

### Shared Context Files
- `.specify/memory/constitution.md` - Project rules (read by all workflows)
- `.specify/memory/project-context.md` - Current state (read by all workflows)
- `.specify/templates/*.md` - Document templates (read by generation workflows)

---

## Summary

This data model defines:
1. **5 core entities**: WorkflowDefinition, WorkflowFrontmatter, HandoffConfiguration, ScriptInvocation, ArgumentSubstitution
2. **Common workflow graph**: specify → plan → tasks → implement
3. **Dual-location strategy**: `.agent/workflows/` (Antigravity) + `.claude/commands/` (Claude)
4. **Script conventions**: Bash (Claude) + PowerShell (Antigravity), JSON output
5. **Naming patterns**: `namespace.workflow-name.md`, `action-noun.ext`

All entities support both Antigravity IDE and Claude Code with minimal format differences (script path only).

---

**Phase 1 Status**: In Progress (data-model.md complete)
**Next Artifact**: contracts/
**Date Completed**: 2026-01-12
