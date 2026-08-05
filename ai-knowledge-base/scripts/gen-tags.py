#!/usr/bin/env python3
"""
gen-tags.py — Auto-generate tags for any KB project from article body content.

Detects domain-relevant keywords automatically using pattern matching on the
article body — no hardcoded per-project keyword lists needed.

Usage:
    uv run python gen-tags.py                   # dry-run
    uv run python gen-tags.py --apply           # write changes
    uv run python gen-tags.py --project ../sadeem  # specific project

Dependencies: stdlib only
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

# ── Universal tech keyword patterns — works for any project ──
TECH_KEYWORDS = {
    # Backend: PHP/Laravel
    r"\blaravel\b": "laravel",
    r"\bphp\d?\b": "php",
    r"\b(eloquent|orm)\b": "eloquent",
    r"\bblade\b": "blade",
    r"\bartisan\b": "artisan",
    r"\bmiddleware\b": "middleware",
    r"\b(migrations?|migrate)\b": "migration",
    r"\bseeder\b": "seeder",
    r"\b(queue|queues?)\b": "queue",
    r"\bevent\b": "event",
    r"\blistener\b": "listener",
    r"\bnotification\b": "notification",
    r"\b(policies?|gate)\b": "policy",
    r"\bvalidation\b": "validation",
    r"\broute\b": "route",
    r"\bcontrollers?\b": "controller",
    r"\bmodel\b": "model",
    r"\bfilament\b": "filament",
    r"\bsanctum\b": "sanctum",

    # Backend: Python/Django/FastAPI
    r"\bdjango\b": "django",
    r"\bfastapi\b": "fastapi",
    r"\bflask\b": "flask",
    r"\bpython\b": "python",

    # Frontend: React/Next.js
    r"\bnext(\.?js)?\b": "nextjs",
    r"\breact\b": "react",
    r"\btailwind\b": "tailwind",
    r"\btypescript\b": "typescript",
    r"\bjavascript\b": "javascript",
    r"\bframer(-| )motion\b": "framer-motion",
    r"\bgsap\b": "gsap",
    r"\blucide\b": "lucide",
    r"\bsonner\b": "sonner",
    r"\bcomponent\b": "component",

    # Infrastructure
    r"\bdocker\b": "docker",
    r"\b(docker-compose|compose)\b": "docker-compose",
    r"\bnginx\b": "nginx",
    r"\bapache\b": "apache",
    r"\bmysql\b": "mysql",
    r"\b(postgres|postgresql|pgsql)\b": "postgresql",
    r"\bredis\b": "redis",
    r"\bmariadb\b": "mariadb",
    r"\bcloudflare\b": "cloudflare",
    r"\b(ssl|tls)\b": "ssl",
    r"\bcertificates?\b": "certificate",
    r"\bk3s\b": "k3s",
    r"\bkubernetes\b": "kubernetes",
    r"\b(containers?|containerization)\b": "container",
    r"\bgithub[- ]actions\b": "github-actions",
    r"\bcicd\b": "ci-cd",
    r"\bdeploy\b": "deployment",
    r"\btraefik\b": "traefik",

    # Database
    r"\bdatabase\b": "database",
    r"\bschema\b": "schema",
    r"\bindexing?\b": "indexing",
    r"\bquery\b": "query",
    r"\b(relationships?|relation)\b": "relationship",
    r"\b(seeding|seed)\b": "seeding",

    # Security
    r"\bauth(en[td]?ication|enticate)?\b": "auth",
    r"\bjwt\b": "jwt",
    r"\bsanctum\b": "sanctum",
    r"\b(password|passwords?)\b": "password",
    r"\b(encrypt|decrypt)\b": "encryption",
    r"\b(permissions?|roles?|authorization?)\b": "permissions",
    r"\bxss\b": "xss",
    r"\bsql[- ]?injection\b": "sql-injection",
    r"\bcsrf\b": "csrf",
    r"\bcors\b": "cors",
    r"\brate[- ]?limit\b": "rate-limiting",

    # Architecture
    r"\barchitecture\b": "architecture",
    r"\bpattern\b": "pattern",
    r"\banti[ -]?pattern\b": "antipattern",
    r"\brefactor(ing|or)?\b": "refactoring",
    r"\b(optimize|optimization)\b": "optimization",
    r"\bcache\b": "caching",

    # AI/ML
    r"\b(ai|artificial intelligence)\b": "ai",
    r"\bmachine[- ]?learning\b": "machine-learning",
    r"\bllm\b": "llm",
    r"\b(rag|retrieval[- ]?augmented)\b": "rag",
    r"\b(openai|gpt|chatgpt)\b": "openai",
    r"\bembeddings?\b": "embedding",
    r"\bvector\b": "vector-database",
    r"\b(search|recommendation|personalization)\b": "search",

    # Testing
    r"\btest(ing|s)?\b": "testing",
    r"\bphpunit\b": "phpunit",
    r"\bpest\b": "pest",
    r"\bjest\b": "jest",
    r"\bcypress\b": "cypress",
    r"\bcoverage\b": "coverage",

    # DevOps
    r"\bpanel\b": "panel",
    r"\b(ci|cd)\b": "ci-cd",
    r"\bgithub[- ]?actions\b": "github-actions",
    r"\b(monitoring|logs?|logging)\b": "monitoring",
    r"\b(probe|health[- ]?check|liveness|readiness)\b": "health-check",
    r"\bbackup\b": "backup",

    # Design
    r"\b(ui|ux)\b": "ui",
    r"\bresponsive\b": "responsive",
    r"\bmobile[- ]?first\b": "mobile-first",
    r"\b(rtl|right[- ]?to[- ]?left)\b": "rtl",
    r"\b(arabic|i18n|internationalization|localization)\b": "i18n",
    r"\btheme\b": "theme",
    r"\bdark[- ]?mode\b": "dark-mode",
    r"\btypography\b": "typography",
    r"\banimation\b": "animation",
    r"\bdark[- ]?mode\b": "dark-mode",
    r"\btheming\b": "theming",

    # Email
    r"\bemail\b": "email",
    r"\b(smtp|mail)\b": "smtp",
    r"\bses\b": "ses",
    r"\bmailgun\b": "mailgun",
    r"\bsendgrid\b": "sendgrid",

    # Mobile / Notifications
    r"\b(firebase|firestore)\b": "firebase",
    r"\bfcm\b": "fcm",
    r"\bsms\b": "sms",
    r"\bwhatsapp\b": "whatsapp",
    r"\bslack\b": "slack",

    # Payment
    r"\bpayment\b": "payment",
    r"\bstripe\b": "stripe",
    r"\b(google[- ]?pay|gpay)\b": "google-pay",
    r"\b(apple[- ]?pay|apay)\b": "apple-pay",
    r"\bbank[- ]?transfer\b": "bank-transfer",
    r"\bwallet\b": "wallet",

    # Laravel-specific features
    r"\bservice[- ]?provider\b": "service-provider",
    r"\bfacade\b": "facade",
    r"\btrait\b": "trait",
    r"\bscope\b": "scope",
    r"\b(mutator|accessor)\b": "mutator",
    r"\b(cast|casting)\b": "casting",
    r"\b(collection|collect)\b": "collection",
    r"\b(helper|helpers?)\b": "helper",
    r"\bmacro\b": "macro",
    r"\b(console|command)\b": "command",
    r"\bschedule\b": "scheduler",
    r"\b(telescope|debugbar|debug)\b": "debugging",

    # Generic tech
    r"\b(api|rest|restful)\b": "api",
    r"\bchat\b": "chat",
    r"\bgraphql\b": "graphql",
    r"\bwebsocket\b": "websocket",
    r"\b(sse|server[- ]?sent[- ]?events)\b": "sse",
    r"\b(env|environment|\.env)\b": "environment",
    r"\b(cli|command[- ]?line)\b": "cli",
    r"\b(vagrant|homestead)\b": "vagrant",
    r"\b(provision|ansible)\b": "provisioning",
    r"\b(dns|domain)\b": "dns",
    r"\bcdn\b": "cdn",
    r"\bload[- ]?balanc(er|ing)\b": "load-balancing",
}

# Keywords that are too generic — skip unless they appear multiple times
GENERIC = {
    "api", "command", "component", "controller", "database", "deployment",
    "email", "environment", "indexing", "migration", "monitoring", "notification",
    "password", "query", "relationship", "theme", "validation",
}

# Project-specific compound keywords (detected by project name)
PROJECT_COMPOUND = {
    "surian": [
        r"\b(surian\b.{0,50}admin|admin.{0,50}surian)",
        r"\b(hostpath|host-path)\b",
    ],
    "beldify": [
        r"\bimage[- ]?export\b",
        r"\b(pix[- ]?invent|pixinvent)\b",
        r"\bmulti[- ]?seller\b",
        r"\btailoring\b",
    ],
    "sadeem": [
        r"\b(sadeem\b.{0,50}moe|moe.{0,50}sadeem)",
        r"\b(panel|parity|verdict)\b",
        r"\b(prompt|stubs|diff)\b",
    ],
}


def detect_compound(text: str, project: str) -> list[str]:
    """Detect project-specific compound terms."""
    found: list[str] = []
    for pattern in PROJECT_COMPOUND.get(project, []):
        if re.search(pattern, text, re.IGNORECASE):
            found.append(project)
    return found


def gen_tags(body: str, project: str = "") -> list[str]:
    """Auto-detect tags from article body. Returns up to 12 tags."""
    text = body.lower()
    found: list[str] = []

    for pattern, tag in TECH_KEYWORDS.items():
        if re.search(pattern, text, re.IGNORECASE):
            found.append(tag)

    # Project-specific compounds
    found.extend(detect_compound(text, project))

    # Fallback: if nothing found, add a generic tag
    if not found:
        found.append("reference")

    # Remove generics unless they appear more than once
    counted: dict[str, int] = {}
    for tag in found:
        counted[tag] = counted.get(tag, 0) + 1

    filtered: list[str] = []
    for tag in found:
        c = counted[tag]
        if tag in GENERIC and c < 2:
            continue
        filtered.append(tag)

    # Deduplicate preserving order
    seen: set[str] = set()
    result: list[str] = []
    for tag in filtered:
        if tag not in seen:
            seen.add(tag)
            result.append(tag)

    return result[:12]


def fix_file(file_path: Path, project: str, apply: bool, changes: list) -> bool:
    """Add tags to a file that has empty tags: []. Returns True if changed."""
    text = file_path.read_text(encoding="utf-8")

    if not text.startswith("---"):
        return False
    parts = text.split("---", 2)
    if len(parts) < 3:
        return False

    fm = parts[1]
    body = parts[2]

    # Check for empty tags line
    fm_lines = fm.split("\n")
    new_lines: list[str] = []
    found_empty = False
    for line in fm_lines:
        stripped = line.strip()
        if stripped == "tags: []":
            found_empty = True
            continue
        new_lines.append(line)

    if not found_empty:
        return False

    # Extract body content for keyword analysis
    body_text = re.sub(r"^#.*\n", "", body, flags=re.MULTILINE)
    keywords = gen_tags(body_text, project)
    if not keywords:
        return False

    tags_str = ", ".join(keywords)
    result_lines: list[str] = []
    inserted = False

    for line in new_lines:
        result_lines.append(line)
        stripped = line.strip()
        if not inserted and stripped.startswith("type:"):
            result_lines.append(f"tags: [{tags_str}]")
            inserted = True

    if not inserted:
        result_lines = []
        for line in new_lines:
            result_lines.append(line)
            stripped = line.strip()
            if not inserted and stripped.startswith("name:"):
                result_lines.append(f"tags: [{tags_str}]")
                inserted = True

    new_fm = "\n".join(result_lines)
    new_text = f"---{new_fm}---{body}"

    try:
        knowledge_idx = file_path.parts.index("knowledge")
        rel = Path(*file_path.parts[knowledge_idx + 1:])
    except ValueError:
        rel = file_path.relative_to(file_path.parent.parent)

    changes.append({"rel": str(rel), "tags": keywords})

    if apply:
        file_path.write_text(new_text, encoding="utf-8")
    return True


def scan_kb(root: Path) -> list[Path]:
    """Scan KB directory for all .md files."""
    knowledge_dir = root / "ai-knowledge-base" / "knowledge"
    files: list[Path] = []
    if knowledge_dir.is_dir():
        for subdir in ("concepts", "connections", "sources", "entities", "qa"):
            d = knowledge_dir / subdir
            if d.is_dir():
                files.extend(sorted(d.glob("*.md")))
    return files


def main():
    parser = argparse.ArgumentParser(
        description="Auto-generate tags for any KB project."
    )
    parser.add_argument("--apply", action="store_true", help="Write changes")
    parser.add_argument("--project", type=str, help="Project root (default: cwd)")
    args = parser.parse_args()

    if args.project:
        root = Path(args.project).resolve()
    else:
        root = Path.cwd().resolve()

    project_name = root.name
    print(f"📁 Project: {project_name}")
    files = scan_kb(root)

    if not files:
        print("  No KB articles found.")
        return

    changes: list[dict] = []
    for fp in files:
        fix_file(fp, project_name, args.apply, changes)

    if not changes:
        print("  ✅ All articles already have tags.")
        return

    mode = "DRY-RUN" if not args.apply else f"APPLIED ({len(changes)} files)"
    print(f"\n  {mode}:\n")

    for item in changes:
        print(f"  📄 {item['rel']}")
        print(f"     tags: [{', '.join(item['tags'])}]")
        print()

    if not args.apply:
        print(f"  ⚠️  Dry-run only. Run with --apply.")


if __name__ == "__main__":
    main()
