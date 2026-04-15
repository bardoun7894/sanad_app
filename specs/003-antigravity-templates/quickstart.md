# Quickstart: Unified Multi-Agent Workflows

**Feature**: 003-antigravity-templates
**Date**: 2026-01-12
**Phase**: 1 (Design & Contracts)

---

## 🚀 What is This?

This project includes a **Unified Multi-Agent Workflow System** that provides structured development workflows for both **Antigravity IDE** and **Claude Code**. The workflows guide you through feature development using a consistent process:

```
specify → plan → tasks → implement → analyze
```

---

## 📋 Quick Reference

### Available Workflows

| Workflow | Command | Purpose |
|----------|---------|---------|
| **specify** | `/speckit.specify` | Create feature specification from natural language |
| **plan** | `/speckit.plan` | Generate implementation plan with architecture |
| **tasks** | `/speckit.tasks` | Break plan into actionable tasks |
| **implement** | `/speckit.implement` | Execute task list |
| **clarify** | `/speckit.clarify` | Ask clarification questions on spec |
| **analyze** | `/speckit.analyze` | Validate consistency across artifacts |
| **constitution** | `/speckit.constitution` | View/update project constitution |
| **checklist** | `/speckit.checklist` | Generate verification checklist |
| **taskstoissues** | `/speckit.taskstoissues` | Convert tasks to GitHub issues |

---

## 🎯 5-Minute Workflow Example

### Step 1: Create a Feature Spec
```bash
/speckit.specify "Add user profile editing feature"
```

**Output**: `specs/004-user-profile-edit/spec.md`
- User stories
- Requirements
- Success criteria

### Step 2: Generate Implementation Plan
```bash
/speckit.plan specs/004-user-profile-edit
```

**Output**: `specs/004-user-profile-edit/plan.md`
- Technical context
- Constitution check
- Research findings
- Data model
- Contracts

### Step 3: Break into Tasks
```bash
/speckit.tasks specs/004-user-profile-edit
```

**Output**: `specs/004-user-profile-edit/tasks.md`
- Dependency-ordered tasks
- Estimated effort
- Critical path

### Step 4: Implement
```bash
/speckit.implement specs/004-user-profile-edit
```

**Executes**: All tasks in `tasks.md`, one by one

### Step 5: Validate
```bash
/speckit.analyze specs/004-user-profile-edit
```

**Output**: Analysis report showing:
- Coverage gaps
- Duplications
- Constitution violations
- Ambiguities

---

## 🛠️ Setup Guide

### For Claude Code Users

#### Prerequisites
- Claude Code CLI installed
- Bash 4.0+ (check: `bash --version`)
- `jq` installed (check: `which jq`)

#### Verify Installation
```bash
# Check if workflows exist
ls -la .claude/commands/speckit.*.md

# You should see 9 files:
# - speckit.specify.md
# - speckit.plan.md
# - speckit.tasks.md
# - speckit.implement.md
# - speckit.clarify.md
# - speckit.analyze.md
# - speckit.constitution.md
# - speckit.checklist.md
# - speckit.taskstoissues.md
```

#### Test a Workflow
```bash
# Try viewing the constitution
/speckit.constitution
```

If this works, you're all set! ✅

---

### For Antigravity IDE Users

#### Prerequisites
- Antigravity IDE installed
- PowerShell 5.1+ (Windows) or PowerShell Core (macOS/Linux)

#### Verify Installation
```powershell
# Check if workflows exist
Get-ChildItem .agent/workflows/speckit.*.md

# You should see 9 files (same as Claude)
```

#### Test a Workflow
In Antigravity IDE:
1. Type `@[/speckit.constitution]`
2. Press Enter
3. Should display the project constitution

If this works, you're all set! ✅

---

## 📂 Project Structure

```text
your-project/
├── .agent/
│   └── workflows/           # Antigravity workflows
│       ├── speckit.specify.md
│       ├── speckit.plan.md
│       ├── speckit.tasks.md
│       └── ... (9 total)
│
├── .claude/
│   └── commands/            # Claude Code skills
│       ├── speckit.specify.md
│       ├── speckit.plan.md
│       ├── speckit.tasks.md
│       └── ... (9 total)
│
├── .specify/
│   ├── memory/
│   │   ├── constitution.md  # Project rules
│   │   └── project-context.md # Current state
│   ├── scripts/
│   │   ├── bash/            # Claude scripts
│   │   │   ├── setup-plan.sh
│   │   │   ├── setup-tasks.sh
│   │   │   └── ...
│   │   └── powershell/      # Antigravity scripts
│   │       ├── setup-plan.ps1
│   │       ├── setup-tasks.ps1
│   │       └── ...
│   └── templates/
│       ├── spec-template.md
│       ├── plan-template.md
│       └── tasks-template.md
│
└── specs/                   # Feature specifications
    ├── 001-feature-name/
    │   ├── spec.md
    │   ├── plan.md
    │   ├── tasks.md
    │   ├── research.md
    │   ├── data-model.md
    │   └── contracts/
    ├── 002-another-feature/
    │   └── ...
    └── 003-antigravity-templates/ # This feature!
        ├── spec.md
        ├── plan.md
        ├── research.md
        ├── data-model.md
        ├── contracts/
        └── quickstart.md (you are here)
```

---

## 🔄 Workflow Graph

```
                      ┌──────────────────┐
                      │  Constitution    │
                      │  (Always visible)│
                      └──────────────────┘
                               │
                               ▼
                      ┌──────────────────┐
                      │   Specify        │◄──── User describes feature
                      │  (Create spec)   │
                      └────────┬─────────┘
                               │
                               ▼
                      ┌──────────────────┐
       ┌─────────────►│    Clarify       │ (Optional - ask questions)
       │              └──────────────────┘
       │                       │
       │                       ▼
       │              ┌──────────────────┐
       │              │      Plan        │
       │              │ (Architecture)   │
       │              └────────┬─────────┘
       │                       │
       │                       ▼
       │              ┌──────────────────┐
       │              │     Tasks        │
       │              │ (Break down)     │
       │              └────────┬─────────┘
       │                       │
       │                       ├──────────────┐
       │                       │              ▼
       │                       │     ┌──────────────────┐
       │                       │     │    Analyze       │
       │                       │     │ (Validate)       │
       │                       │     └──────────────────┘
       │                       │
       │                       ▼
       │              ┌──────────────────┐
       └──────────────│   Implement      │
                      │ (Execute tasks)  │
                      └────────┬─────────┘
                               │
                               ▼
                      ┌──────────────────┐
                      │   Checklist      │
                      │  (Verify done)   │
                      └──────────────────┘
```

**Parallel Workflows** (can be invoked anytime):
- `/speckit.constitution` - View project rules
- `/speckit.checklist` - Generate verification checklist
- `/speckit.taskstoissues` - Push tasks to GitHub

---

## 📖 Detailed Workflow Usage

### `/speckit.specify` - Create Feature Spec

**Purpose**: Convert a natural language description into a structured feature spec.

**Input**: Feature description (1-3 sentences)

**Example**:
```bash
/speckit.specify "Add dark mode toggle to user profile. Should persist across sessions and apply to all screens."
```

**Output**: `specs/005-dark-mode/spec.md` containing:
- User stories (prioritized)
- Functional requirements (FR-001, FR-002, ...)
- Non-functional requirements (performance, security, etc.)
- Success criteria (measurable outcomes)
- Edge cases

**When to use**: Start of any new feature development.

---

### `/speckit.plan` - Generate Implementation Plan

**Purpose**: Design the implementation approach with architecture and data models.

**Input**: Feature directory path

**Example**:
```bash
/speckit.plan specs/005-dark-mode
```

**Output**: `specs/005-dark-mode/` containing:
- `plan.md` - Technical context, constitution check, project structure
- `research.md` - Research findings and decisions
- `data-model.md` - Entity definitions and relationships
- `contracts/` - API schemas or interface definitions

**When to use**: After spec is complete, before starting implementation.

---

### `/speckit.tasks` - Break into Tasks

**Purpose**: Convert the plan into a dependency-ordered task list.

**Input**: Feature directory path

**Example**:
```bash
/speckit.tasks specs/005-dark-mode
```

**Output**: `specs/005-dark-mode/tasks.md` containing:
- Task ID, description, estimated effort
- Dependencies (task ordering)
- Parallel markers `[P]` for parallelizable tasks
- File paths to modify/create

**When to use**: After plan is complete, before implementation.

---

### `/speckit.implement` - Execute Tasks

**Purpose**: Execute each task in the task list sequentially.

**Input**: Feature directory path

**Example**:
```bash
/speckit.implement specs/005-dark-mode
```

**Process**:
1. Reads `specs/005-dark-mode/tasks.md`
2. Executes tasks in dependency order
3. Marks completed tasks with ✅
4. Stops on errors and reports progress

**When to use**: After tasks are approved, ready to code.

---

### `/speckit.analyze` - Validate Consistency

**Purpose**: Identify inconsistencies, gaps, and violations across spec/plan/tasks.

**Input**: Feature directory path

**Example**:
```bash
/speckit.analyze specs/005-dark-mode
```

**Output**: Analysis report showing:
- Duplication (requirements/tasks)
- Ambiguity (vague terms)
- Coverage gaps (requirements without tasks)
- Constitution violations
- Severity ratings (CRITICAL/HIGH/MEDIUM/LOW)

**When to use**: After tasks are generated, before implementation starts.

---

### `/speckit.clarify` - Ask Clarification Questions

**Purpose**: Identify underspecified areas in the spec and ask targeted questions.

**Input**: Feature directory path

**Example**:
```bash
/speckit.clarify specs/005-dark-mode
```

**Output**: Up to 5 clarification questions about:
- Vague requirements
- Missing acceptance criteria
- Undefined edge cases

**When to use**: When spec feels incomplete or vague.

---

### `/speckit.constitution` - View Project Rules

**Purpose**: Display the project constitution (governance rules).

**Input**: None

**Example**:
```bash
/speckit.constitution
```

**Output**: Displays `.specify/memory/constitution.md`

**When to use**: Anytime you need to check project rules.

---

### `/speckit.checklist` - Generate Verification Checklist

**Purpose**: Create a custom checklist for verifying feature completion.

**Input**: Feature directory path or requirements

**Example**:
```bash
/speckit.checklist specs/005-dark-mode
```

**Output**: Markdown checklist with:
- Feature requirements (one checkbox per requirement)
- Testing steps
- Documentation updates
- Deployment verification

**When to use**: Before marking feature complete.

---

### `/speckit.taskstoissues` - Convert Tasks to GitHub Issues

**Purpose**: Create GitHub issues from tasks.md.

**Input**: Feature directory path

**Example**:
```bash
/speckit.taskstoissues specs/005-dark-mode
```

**Output**: Creates GitHub issues with:
- Issue title = task description
- Labels = task type (implementation, testing, etc.)
- Assignee = you (optional)
- Dependencies referenced in issue body

**When to use**: When working with a team, need to track tasks in GitHub.

---

## ⚠️ Common Issues

### Issue: "Script not found: setup-plan.sh"

**Problem**: Automation scripts don't exist yet.

**Solution**: The scripts referenced by workflows haven't been created. This is expected for the current state. Workflows can still be executed manually without the scripts.

**Workaround**:
1. Manually create feature directories: `mkdir -p specs/feature-name`
2. Copy templates manually: `cp .specify/templates/spec-template.md specs/feature-name/spec.md`

**Permanent Fix**: Create the 5 missing scripts (see `research.md` for details):
- `setup-plan.sh`
- `setup-tasks.sh`
- `setup-specify.sh`
- `check-prerequisites.sh`
- `update-agent-context.sh`

---

### Issue: "Workflow not recognized"

**Problem**: Workflow file doesn't exist in expected location.

**Solution (Claude Code)**:
```bash
# Verify file exists
ls .claude/commands/speckit.plan.md

# If missing, check you're in project root
pwd

# Should show: /Users/[you]/sanad_app
```

**Solution (Antigravity)**:
1. Check `.agent/workflows/` directory
2. Verify file has `.md` extension
3. Restart Antigravity IDE

---

### Issue: "Permission denied" when running scripts

**Problem**: Bash scripts don't have execute permissions.

**Solution**:
```bash
# Add execute permissions to all bash scripts
chmod +x .specify/scripts/bash/*.sh
```

---

## 🎓 Best Practices

### 1. Always Start with Specify
Don't skip the spec phase. A clear spec saves hours of rework.

```bash
# ✅ Good
/speckit.specify "Feature description"
/speckit.plan specs/feature-name
/speckit.tasks specs/feature-name

# ❌ Bad (skips spec)
/speckit.tasks specs/feature-name  # No spec to read!
```

### 2. Run Analyze Before Implement
Catch issues early.

```bash
/speckit.tasks specs/feature-name
/speckit.analyze specs/feature-name  # ← Do this!
/speckit.implement specs/feature-name
```

### 3. Use Clarify When Stuck
If you're unsure about requirements, ask.

```bash
/speckit.clarify specs/feature-name
```

### 4. Check Constitution Regularly
Ensure your work aligns with project rules.

```bash
/speckit.constitution
```

### 5. Version Your Specs
Keep specs in `specs/` directory with numbered prefixes.

```
specs/
├── 001-initial-feature/
├── 002-another-feature/
├── 003-antigravity-templates/  ← Sequential numbering
└── 004-next-feature/
```

---

## 🔗 Resources

### Documentation
- **Constitution**: `.specify/memory/constitution.md` - Project rules
- **Project Context**: `.specify/memory/project-context.md` - Current state
- **Templates**: `.specify/templates/` - Base templates
- **Contracts**: `specs/003-antigravity-templates/contracts/` - Format specifications

### Schemas
- **Antigravity**: `contracts/antigravity-workflow-schema.yaml`
- **Claude**: `contracts/claude-skill-schema.md`
- **Data Model**: `data-model.md`

### Research
- **Findings**: `research.md` - All research decisions and rationale

---

## 🤝 Contributing Workflows

Want to add a custom workflow?

### For Sanad App

1. Create workflow file:
   ```bash
   touch .agent/workflows/sanad.your-workflow.md
   touch .claude/commands/sanad.your-workflow.md
   ```

2. Add YAML frontmatter:
   ```yaml
   ---
   description: What your workflow does
   handoffs:
     - label: Next Step
       agent: speckit.implement
       prompt: Execute the workflow
       send: false
   ---
   ```

3. Write Markdown instructions

4. Test in both agents

5. Document in this quickstart

---

## ✅ Summary

You now have access to 9 powerful workflows that guide you through structured feature development:

1. **specify** - Create feature spec
2. **plan** - Design implementation
3. **tasks** - Break into tasks
4. **implement** - Execute tasks
5. **clarify** - Ask questions
6. **analyze** - Validate consistency
7. **constitution** - View rules
8. **checklist** - Generate verification checklist
9. **taskstoissues** - Push to GitHub

**Start here**: `/speckit.specify "Your feature idea"`

**Get help**: Read the constitution (`/speckit.constitution`) or ask clarification questions (`/speckit.clarify`)

---

**Status**: ✅ Complete
**Last Updated**: 2026-01-12
**Maintained By**: Sanad App Development Team
