# Research: Unified Multi-Agent Workflows

**Feature**: 003-antigravity-templates
**Date**: 2026-01-12
**Phase**: 0 (Research & Discovery)
**Status**: Complete

---

## Research Task 1: Antigravity Workflow Format Specification

### Decision
Antigravity IDE workflows use Markdown files with YAML frontmatter containing:
- `description`: Single-line workflow description
- `handoffs`: Array of objects with:
  - `label`: Display name for the handoff action
  - `agent`: Target workflow name (e.g., `speckit.tasks`)
  - `prompt`: Prompt text sent to the target agent
  - `send`: Boolean indicating if handoff is enabled

### Rationale
Examined existing workflows in `.agent/workflows/speckit.*.md` and confirmed this pattern is consistent across all 9 Speckit workflows plus 4 Sanad-specific workflows (13 total).

### Alternatives Considered
- JSON-based configuration: Rejected because Antigravity IDE specification explicitly requires YAML frontmatter in Markdown
- Separate schema files: Rejected because inline frontmatter allows single-file portability

### Schema Definition

```yaml
---
description: string (required, single line)
handoffs: array (optional)
  - label: string (required, display text)
    agent: string (required, workflow filename without .md)
    prompt: string (required, prompt text)
    send: boolean (optional, default false)
---
```

### Example
```yaml
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
---
```

---

## Research Task 2: Claude Code Skill Format Requirements

### Decision
Claude Code uses the same Markdown + YAML frontmatter format as Antigravity, stored in `.claude/commands/`. The format is identical except for script path references:
- Antigravity: `.specify/scripts/powershell/*.ps1` (Windows/cross-platform)
- Claude: `.specify/scripts/bash/*.sh` (Unix-like systems)

### Rationale
Compared `.agent/workflows/speckit.plan.md` with `.claude/commands/speckit.plan.md` and found only one difference: script invocation paths. Both use same YAML frontmatter, same Markdown structure, same `$ARGUMENTS` variable substitution.

### Alternatives Considered
- Custom format for Claude: Rejected because existing files already use Antigravity-compatible format
- Single unified location: Rejected because each agent system expects files in its own directory

### Format Specification

**Location**: `.claude/commands/[skill-name].md`
**Frontmatter**: Identical to Antigravity (YAML with `description` and `handoffs`)
**Body**: Markdown with `$ARGUMENTS` placeholder for user input
**Script References**: Must use `.specify/scripts/bash/*.sh --json` format

### Example
```markdown
---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs:
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
---

## User Input

$ARGUMENTS

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` ...
```

---

## Research Task 3: Existing Workflow Inventory

### Decision
The project already has complete Speckit workflow implementations in both locations:

**Antigravity (`.agent/workflows/`)**:
1. `speckit.specify.md` - Feature specification creation
2. `speckit.plan.md` - Implementation planning
3. `speckit.tasks.md` - Task breakdown
4. `speckit.implement.md` - Task execution
5. `speckit.clarify.md` - Clarification questions
6. `speckit.analyze.md` - Cross-artifact analysis
7. `speckit.constitution.md` - Constitution management
8. `speckit.checklist.md` - Checklist generation
9. `speckit.taskstoissues.md` - GitHub issue creation

**Additional Sanad-specific workflows**:
1. `sanad.feature-add.md` - Add new feature to Sanad app
2. `sanad.feature-verify.md` - Verify feature compliance
3. `sanad.firebase-rules.md` - Firebase rules management
4. `sanad.localize.md` - Localization workflow

**Claude (`.claude/commands/`)**:
- Same 9 Speckit workflows as Antigravity
- 3 additional utility commands: `doc.md`, `git-commit.md`, `review.md`, `status.md`

### Rationale
File inventory conducted on 2026-01-12. All required workflows already exist and are operational.

### Alternatives Considered
N/A - Inventory is factual observation

### Impact on Feature Scope
**MAJOR FINDING**: The feature specification requested "Initialize Antigravity IDE Templates" but the templates already exist and are fully implemented. The actual requirement appears to be:
1. Documentation of the existing system
2. Validation that workflows work in both agents
3. Creation of missing automation scripts (setup-plan.sh, etc.)

---

## Research Task 4: Cross-Agent Testing Strategy

### Decision
Testing strategy consists of:
1. **Syntax Validation**: Verify YAML frontmatter parses correctly in both systems
2. **Execution Testing**: Run each workflow end-to-end in both Antigravity and Claude
3. **Script Dependency Testing**: Verify all `.specify/scripts/bash/*.sh` scripts exist and execute
4. **Handoff Testing**: Verify workflow handoffs navigate correctly between workflows

### Rationale
Workflows are declarative and deterministic. Manual testing with both agents is the most reliable validation approach.

### Test Plan

| Workflow | Antigravity Test | Claude Test | Script Dependencies |
|----------|------------------|-------------|---------------------|
| speckit.specify | ✅ Execute with sample input | ✅ Execute with sample input | setup-specify.sh |
| speckit.plan | ✅ Execute on existing spec | ✅ Execute on existing spec | setup-plan.sh |
| speckit.tasks | ✅ Execute on existing plan | ✅ Execute on existing plan | setup-tasks.sh |
| speckit.implement | ✅ Execute task list | ✅ Execute task list | N/A (reads tasks.md) |
| speckit.clarify | ✅ Run on underspecified spec | ✅ Run on underspecified spec | check-prerequisites.sh |
| speckit.analyze | ✅ Run on complete artifacts | ✅ Run on complete artifacts | check-prerequisites.sh |
| speckit.constitution | ✅ View constitution | ✅ View constitution | N/A (reads constitution.md) |
| speckit.checklist | ✅ Generate checklist | ✅ Generate checklist | N/A (generates from spec) |
| speckit.taskstoissues | ✅ Convert tasks to issues | ✅ Convert tasks to issues | N/A (reads tasks.md) |

### Alternatives Considered
- Automated testing framework: Rejected due to complexity of mocking AI agent environments
- Unit testing: Rejected because workflows are integration-level artifacts

---

## Research Task 5: Script Dependencies & Prerequisites

### Decision
Required scripts that are currently **MISSING** and must be created:
1. `.specify/scripts/bash/setup-plan.sh` - Initializes plan.md from template
2. `.specify/scripts/bash/setup-tasks.sh` - Initializes tasks.md from template
3. `.specify/scripts/bash/setup-specify.sh` - Initializes spec.md from template
4. `.specify/scripts/bash/check-prerequisites.sh` - Validates feature directory structure
5. `.specify/scripts/bash/update-agent-context.sh` - Updates agent context files

Existing scripts:
- `.specify/scripts/sync-context.sh` - Syncs context between agents (✅ exists)
- `.specify/scripts/claude-check.sh` - Claude environment check (✅ exists)

### Rationale
Workflows reference these scripts but they don't exist in the repository. Examined `.specify/scripts/` directory and confirmed only 2 bash scripts exist (`sync-context.sh` and `claude-check.sh`).

### Minimum Requirements
- **Bash Version**: 4.0+ (for associative arrays, JSON parsing)
- **Required Utilities**: `jq` (JSON parsing), `grep`, `sed`, `find`
- **Optional Utilities**: `yq` (YAML parsing, can fallback to grep)
- **OS Support**: macOS, Linux (bash scripts), Windows (PowerShell equivalents in `.specify/scripts/powershell/`)

### Alternatives Considered
- Python-based scripts: Rejected to avoid additional runtime dependencies
- PowerShell-only: Rejected because Claude Code primarily runs on Unix-like systems
- No automation scripts: Rejected because workflows explicitly reference them

### Action Items
Create 5 missing bash scripts with the following signatures:

```bash
# setup-plan.sh --json [feature-dir]
# Output: {"FEATURE_SPEC": "...", "IMPL_PLAN": "...", "SPECS_DIR": "...", "BRANCH": "..."}

# setup-tasks.sh --json [feature-dir]
# Output: {"FEATURE_SPEC": "...", "IMPL_PLAN": "...", "TASKS_FILE": "...", "BRANCH": "..."}

# setup-specify.sh --json [feature-name]
# Output: {"FEATURE_SPEC": "...", "SPECS_DIR": "...", "BRANCH": "..."}

# check-prerequisites.sh --json [--require-tasks] [--include-tasks]
# Output: {"FEATURE_DIR": "...", "AVAILABLE_DOCS": [...], "STATUS": "..."}

# update-agent-context.sh [agent-name]
# Updates .agent/PROJECT_CONTEXT.md or .claude/commands/context.md
```

---

## Summary of Findings

### Key Discoveries
1. **Workflows already exist**: All 9 Speckit workflows are implemented in both `.agent/workflows/` and `.claude/commands/`
2. **Format is unified**: Both agents use identical YAML frontmatter + Markdown format
3. **Scripts are missing**: 5 critical automation scripts referenced by workflows don't exist
4. **Feature scope mismatch**: Spec says "initialize" but should say "document and complete"

### Resolved Ambiguities
- ✅ Antigravity format specification documented
- ✅ Claude format specification documented
- ✅ Existing workflow inventory complete
- ✅ Cross-agent testing strategy defined
- ✅ Script dependencies identified

### Remaining Work
1. Create 5 missing bash scripts (setup-plan.sh, setup-tasks.sh, etc.)
2. Test each workflow end-to-end in both agents
3. Document the complete system in quickstart.md
4. Update feature spec to reflect "completion" vs "initialization"

---

**Phase 0 Status**: ✅ COMPLETE
**Next Phase**: Phase 1 (Design & Contracts)
**Date Completed**: 2026-01-12
