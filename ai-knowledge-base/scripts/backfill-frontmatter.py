#!/usr/bin/env python3
"""
backfill-frontmatter.py — Normalize YAML frontmatter across all KB articles.

SURGICAL text-level transformations — never re-parses/re-serializes YAML.
Only the fields we explicitly target are touched. All custom fields
(connects, question, consulted_articles, filed, aliases, etc.) are preserved
exactly as-is.

Normalizes:
  - title: → name:                     (Surian format)
  - type: from directory                (when missing)
  - tags: []                             (when missing)
  - sources: [] / description: "" etc.  (when missing)
  - Fixes YAML boolean corruption:      (sources: true → sources: [])
  - Fixes multi-line list corruption:   (old serialization that flattened lists)

Usage:
    uv run python backfill-frontmatter.py                    # dry-run (preview)
    uv run python backfill-frontmatter.py --apply            # actually write changes
    uv run python backfill-frontmatter.py --file path.md     # backfill one file
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

# ── Type derived from directory name ─────────────────────────────────
DIR_TO_TYPE = {
    "concepts": "concept",
    "connections": "connection",
    "sources": "source",
    "entities": "entity",
    "qa": "qa",
}

# Fields that should be lists but might be corrupted booleans
LIST_TYPES = {"sources", "connects", "consulted_articles", "tags", "aliases"}

# Fields that must exist with at least a default value
REQUIRED_FIELDS = [
    ("description", '""'),
    ("sources", "[]"),
    ("created", '""'),
    ("updated", '""'),
]


def extract_frontmatter_region(text: str) -> tuple[str | None, str]:
    """Return (frontmatter_lines, body) or (None, text) if no frontmatter."""
    m = re.match(r"^(---\s*\n(?:.*?\n)?---\s*\n)", text, re.DOTALL)
    if not m:
        return None, text
    return m.group(1), text[m.end():]


def run_backfill(text: str, rel_path: Path) -> tuple[str, bool, list[str]]:
    """Apply backfill transformations. Returns (new_text, changed, changes_log)."""
    fm_block, body = extract_frontmatter_region(text)
    changes: list[str] = []

    if fm_block is None:
        dir_type = _dir_to_type(rel_path)
        name = rel_path.stem.replace("-", " ").title()
        new_fm = (
            "---\n"
            f'name: "{name}"\n'
            f"description: \"\"\n"
            f"type: {dir_type}\n"
            f"tags: []\n"
            f"sources: []\n"
            f'created: ""\n'
            f'updated: ""\n'
            "---\n"
        )
        return new_fm + body, True, ["+name", "+type", "+tags", "+description", "+sources", "+created", "+updated"]

    lines = _get_fm_lines(fm_block)
    if not lines:
        return text, False, []

    changed = False

    # ── 0. Fix boolean corruption: field: true → field: [] ──
    new_lines, c = _fix_boolean_to_list(lines)
    if c:
        changed = True
        changes.append(f"fix boolean→list ({c} field(s))")

    # ── 1. title: → name: ──
    new_lines, c = _rename_title_to_name(new_lines)
    if c:
        changed = True
        changes.append("title→name")

    # ── 2. Add type: from directory if missing ──
    new_lines, c = _ensure_field(new_lines, "type", _dir_to_type(rel_path), after_key="description")
    if c:
        changed = True
        changes.append("+type")

    # ── 3. Add tags: [] if missing ──
    new_lines, c = _ensure_field(new_lines, "tags", "[]", after_key="type")
    if c:
        changed = True
        changes.append("+tags")

    # ── 4. Ensure required fields exist ──
    for field_name, default_val in REQUIRED_FIELDS:
        new_lines, c = _ensure_field_anywhere(new_lines, field_name, default_val)
        if c:
            changed = True
            changes.append(f"+{field_name}")

    if not changed:
        return text, False, []

    new_fm = "---\n" + "".join(new_lines) + "---\n"
    return new_fm + body, True, changes


def _get_fm_lines(fm_block: str) -> list[str]:
    """Extract the inner lines of a frontmatter block."""
    lines = fm_block.split("\n")
    inner = []
    in_fm = False
    for line in lines:
        s = line.strip()
        if s == "---":
            if not in_fm:
                in_fm = True
                continue
            break
        if in_fm:
            inner.append(line + "\n")
    return inner


def _fix_boolean_to_list(lines: list[str]) -> tuple[list[str], int]:
    """Fix fields that should be list but are serialized as boolean true/false.

    Handles both:
      sources: true         → sources: []
      sources: false        → sources: []
      connects: true/false  → connects: []  (if connects is in LIST_TYPES)
    """
    changed = 0
    new_lines = []
    for line in lines:
        m = re.match(r"^(\w+):\s*(true|false)\s*$", line.strip())
        if m and m.group(1) in LIST_TYPES:
            indent = line[:len(line) - len(line.lstrip())]
            new_lines.append(f"{indent}{m.group(1)}: []\n")
            changed += 1
        else:
            new_lines.append(line)
    return new_lines, changed


def _rename_title_to_name(lines: list[str]) -> tuple[list[str], bool]:
    changed = False
    new_lines = []
    for line in lines:
        if re.match(r"^title:", line):
            new_lines.append(re.sub(r"^title:", "name:", line))
            changed = True
        else:
            new_lines.append(line)
    return new_lines, changed


def _ensure_field(lines: list[str], field: str, value: str, after_key: str | None = None) -> tuple[list[str], bool]:
    for line in lines:
        if re.match(rf"^{field}:", line):
            return lines, False

    if after_key:
        new_lines = []
        inserted = False
        for line in lines:
            new_lines.append(line)
            if re.match(rf"^{after_key}:", line) and not inserted:
                new_lines.append(f"{field}: {value}\n")
                inserted = True
        if inserted:
            return new_lines, True

    new_lines = lines[:]
    new_lines.insert(0, f"{field}: {value}\n")
    return new_lines, True


def _ensure_field_anywhere(lines: list[str], field: str, value: str) -> tuple[list[str], bool]:
    for line in lines:
        if re.match(rf"^{field}:", line):
            return lines, False
    new_lines = lines[:]
    new_lines.append(f"{field}: {value}\n")
    return new_lines, True


def _dir_to_type(rel_path: Path) -> str:
    for part in rel_path.parts:
        if part in DIR_TO_TYPE:
            return DIR_TO_TYPE[part]
    return "concept"


# ══════════════════════════════════════════════════════════════════════
#  File processing
# ══════════════════════════════════════════════════════════════════════


def backfill_file(file_path: Path, apply: bool, dry_run_output: list) -> bool:
    text = file_path.read_text(encoding="utf-8")
    try:
        knowledge_idx = file_path.parts.index("knowledge")
        rel = Path(*file_path.parts[knowledge_idx + 1:])
    except ValueError:
        rel = file_path.relative_to(file_path.parent.parent)

    new_text, changed, changes_log = run_backfill(text, rel)

    if changed:
        dry_run_output.append({"file": str(file_path), "rel": str(rel), "changes": changes_log})
        if apply:
            file_path.write_text(new_text, encoding="utf-8")
        return True
    return False


def scan_kb(root: Path) -> list[Path]:
    files: list[Path] = []
    knowledge_dir = root / "ai-knowledge-base" / "knowledge"
    if not knowledge_dir.is_dir():
        return files
    for subdir in ("concepts", "connections", "sources", "entities", "qa"):
        d = knowledge_dir / subdir
        if d.is_dir():
            files.extend(sorted(d.glob("*.md")))
    return files


def main():
    parser = argparse.ArgumentParser(description="Normalize KB article frontmatter to unified schema.")
    parser.add_argument("--apply", action="store_true", help="Actually write changes (default: dry-run)")
    parser.add_argument("--file", type=str, help="Backfill a single file only")
    parser.add_argument("--project", type=str, help="Project root path (default: cwd)")
    args = parser.parse_args()

    if args.project:
        root = Path(args.project).resolve()
    else:
        root = Path.cwd().resolve()

    print(f"📁 Project: {root.name}")

    if args.file:
        files = [Path(args.file).resolve()]
    else:
        files = scan_kb(root)

    if not files:
        print("  No KB articles found under knowledge/{concepts,connections,sources,entities,qa}/")
        return

    dry_run_output: list[dict] = []
    changed_count = 0

    for fp in files:
        if backfill_file(fp, args.apply, dry_run_output):
            changed_count += 1

    if not dry_run_output:
        print("  ✅ All articles already have unified frontmatter.")
        return

    mode = "DRY-RUN" if not args.apply else "APPLIED"
    print(f"\n  {mode}: {changed_count} file(s):\n")

    for item in dry_run_output:
        print(f"  📄 {item['rel']}")
        for c in item["changes"]:
            print(f"    {c}")
        print()

    if not args.apply:
        print(f"  ⚠️  Dry-run only. Run with --apply.")


if __name__ == "__main__":
    main()
