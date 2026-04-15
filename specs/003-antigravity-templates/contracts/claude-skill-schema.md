# Claude Code Skill Format Specification

**Version**: 1.0.0
**Date**: 2026-01-12
**Agent System**: Claude Code CLI

---

## Overview

Claude Code skills are Markdown files with YAML frontmatter stored in `.claude/commands/`. The format is nearly identical to Antigravity workflows, with one key difference: script paths use bash scripts (`.specify/scripts/bash/*.sh`) instead of PowerShell.

---

## File Structure

### Location
```
.claude/commands/[skill-name].md
```

### Naming Convention
- Pattern: `[namespace].[skill-name].md`
- Namespace: lowercase, single word (e.g., `speckit`, `sanad`)
- Skill name: lowercase, hyphenated (e.g., `plan`, `tasks-to-issues`)

### Examples
- `speckit.plan.md`
- `speckit.tasks.md`
- `sanad.feature-add.md`

---

## YAML Frontmatter Schema

Skills begin with YAML frontmatter delimited by `---`:

```yaml
---
description: [Single-line description of skill purpose]
handoffs:
  - label: [Display text for handoff action]
    agent: [Target skill name without .md]
    prompt: [Prompt text sent to target skill]
    send: [true/false - whether auto-triggered]
---
```

### Field Definitions

#### `description` (required)
- **Type**: String
- **Format**: Single line (no newlines)
- **Max Length**: 200 characters (recommended)
- **Purpose**: Describes what the skill does
- **Example**: `"Execute the implementation planning workflow using the plan template to generate design artifacts."`

#### `handoffs` (optional)
- **Type**: Array of objects
- **Purpose**: Defines navigation to other skills
- **Can be empty or omitted**

##### Handoff Object Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `label` | string | Yes | Human-readable button text | `"Create Tasks"` |
| `agent` | string | Yes | Target skill filename without `.md` | `"speckit.tasks"` |
| `prompt` | string | Yes | Prompt sent to target skill | `"Break the plan into tasks"` |
| `send` | boolean | No | Auto-trigger flag (default: false) | `true` |

---

## Markdown Body Structure

After the frontmatter, the skill contains Markdown-formatted instructions.

### Standard Sections

Most Speckit skills follow this structure:

```markdown
## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/[script].sh --json` ...
2. **Load context**: Read [files] ...
3. **Execute workflow**: [Steps] ...
4. **Stop and report**: [Output] ...

## [Additional Sections]
...
```

### Variable Substitution

| Variable | Pattern | Source | Description |
|----------|---------|--------|-------------|
| `$ARGUMENTS` | `$ARGUMENTS` | User input | Arguments passed to skill |
| FEATURE_SPEC | Script output | bash script | Path to spec.md |
| IMPL_PLAN | Script output | bash script | Path to plan.md |
| TASKS_FILE | Script output | bash script | Path to tasks.md |
| BRANCH | Script output | bash script | Git branch name |

#### Example

When user invokes:
```
/speckit.plan specs/003-antigravity-templates
```

The skill receives:
- `$ARGUMENTS` = `"specs/003-antigravity-templates"`

---

## Script Invocation Pattern

### Format
```bash
.specify/scripts/bash/[script-name].sh --json [args]
```

### Key Difference from Antigravity
- **Claude**: Uses `.specify/scripts/bash/*.sh` (Unix-like)
- **Antigravity**: Uses `.specify/scripts/powershell/*.ps1` (Windows/cross-platform)

### Standard Scripts

| Script | Purpose | Arguments | Output Keys |
|--------|---------|-----------|-------------|
| `setup-plan.sh` | Initialize plan.md | Feature directory path | FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH |
| `setup-tasks.sh` | Initialize tasks.md | Feature directory path | FEATURE_SPEC, IMPL_PLAN, TASKS_FILE, BRANCH |
| `setup-specify.sh` | Initialize spec.md | Feature name | FEATURE_SPEC, SPECS_DIR, BRANCH |
| `check-prerequisites.sh` | Validate structure | Feature directory path | FEATURE_DIR, AVAILABLE_DOCS, STATUS |
| `update-agent-context.sh` | Update context | Agent name (claude) | N/A (updates files) |

### Script Output Format (JSON)

All scripts that use `--json` flag must output:

```json
{
  "status": "success" | "error",
  "message": "Human-readable status message",
  "data": {
    "FEATURE_SPEC": "/absolute/path/to/spec.md",
    "IMPL_PLAN": "/absolute/path/to/plan.md",
    "SPECS_DIR": "/absolute/path/to/specs",
    "BRANCH": "feature-branch-name"
  }
}
```

### Error Handling

If a script fails:
```json
{
  "status": "error",
  "message": "Feature directory not found: specs/invalid-feature",
  "data": {}
}
```

---

## Complete Example

### File: `.claude/commands/speckit.plan.md`

```markdown
---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
    send: false
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH.

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

[... rest of workflow instructions ...]
```

---

## Invocation

### By User

User types in Claude Code CLI:
```
/speckit.plan specs/003-antigravity-templates
```

Claude Code:
1. Looks for `.claude/commands/speckit.plan.md`
2. Parses YAML frontmatter
3. Substitutes `$ARGUMENTS` with `"specs/003-antigravity-templates"`
4. Executes the skill instructions

### By Handoff

When another skill has a handoff configured:
```yaml
handoffs:
  - label: Create Plan
    agent: speckit.plan
    prompt: Generate implementation plan for this spec
    send: true
```

Claude Code:
1. Shows "Create Plan" button/option
2. If `send: true`, automatically navigates to `speckit.plan`
3. Passes the `prompt` value as context

---

## Validation Rules

Skills must satisfy:

1. **Syntax**: Valid YAML frontmatter + valid Markdown body
2. **Naming**: Filename matches `[namespace].[skill-name].md`
3. **Description**: Single-line, non-empty, < 200 chars
4. **Handoffs** (if present):
   - All `agent` references must point to existing skills
   - All fields (`label`, `agent`, `prompt`) must be non-empty
5. **Script Paths**: Must use `.specify/scripts/bash/*.sh` format
6. **Variable Usage**: `$ARGUMENTS` must appear in body if skill accepts arguments

---

## Differences from Antigravity Format

| Aspect | Antigravity | Claude Code |
|--------|-------------|-------------|
| **Location** | `.agent/workflows/` | `.claude/commands/` |
| **Script Type** | PowerShell (`.ps1`) | Bash (`.sh`) |
| **Script Path** | `.specify/scripts/powershell/` | `.specify/scripts/bash/` |
| **YAML Schema** | ✅ Identical | ✅ Identical |
| **Body Format** | ✅ Identical | ✅ Identical |
| **Variables** | ✅ Identical | ✅ Identical |

---

## Testing Checklist

To validate a Claude Code skill:

- [ ] File exists in `.claude/commands/`
- [ ] Filename follows `[namespace].[skill-name].md` pattern
- [ ] YAML frontmatter parses without errors
- [ ] Description is single-line and < 200 characters
- [ ] All handoff `agent` references point to existing skills
- [ ] All script invocations use `.specify/scripts/bash/*.sh`
- [ ] `$ARGUMENTS` is used correctly if skill accepts input
- [ ] Skill can be invoked via `/[skill-name]` command
- [ ] Script dependencies exist and are executable (`chmod +x`)

---

## Related Specifications

- **Antigravity Schema**: See `antigravity-workflow-schema.yaml` for comparison
- **Data Model**: See `../data-model.md` for entity definitions
- **Templates**: See `.specify/templates/` for base templates

---

**Status**: ✅ Complete
**Last Updated**: 2026-01-12
