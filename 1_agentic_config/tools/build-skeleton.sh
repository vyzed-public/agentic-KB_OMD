#!/usr/bin/env bash
# build-skeleton.sh [SRC] [DST]
# Produce a clean, content-free framework skeleton from a working vault.
#   SRC (default: this repo root) — a vault to harvest the framework from.
#   DST (default: /tmp/wiki-skeleton) — where to write the skeleton.
# Ships the framework (schema, specs, admin, scripts, tests, tools, .claude
# config, .obsidian shared config, .githooks, setup.sh); resets wiki.index.md +
# the log hub to fresh; .gitkeeps the empty data dirs; and EXCLUDES all
# knowledge-base content, the Local REST API key, and personal/workspace files.
set -e
SRC="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
DST="${2:-/tmp/wiki-skeleton}"
rm -rf "$DST"; mkdir -p "$DST"

# --- root framework files ---
cp "$SRC/AGENTS.md"  "$DST/AGENTS.md"
cp "$SRC/.gitignore" "$DST/.gitignore"
cp "$SRC/setup.sh"   "$DST/setup.sh"; chmod +x "$DST/setup.sh"
cp -r "$SRC/.githooks" "$DST/.githooks"
ln -sf AGENTS.md "$DST/CLAUDE.md"
# repo-etiquette files travel if present
if [ -f "$SRC/README.md" ]; then cp "$SRC/README.md" "$DST/README.md"; fi
if [ -f "$SRC/LICENSE" ];   then cp "$SRC/LICENSE"   "$DST/LICENSE";   fi

# --- .claude: settings.json + commands (NOT settings.local.json) ---
mkdir -p "$DST/.claude/commands"
cp "$SRC/.claude/settings.json" "$DST/.claude/settings.json"
if [ -d "$SRC/.claude/commands" ]; then cp -r "$SRC/.claude/commands/." "$DST/.claude/commands/"; fi

# --- 1_agentic_config: specs, admin, scripts, tests, tools (verbatim); logs reset below ---
mkdir -p "$DST/1_agentic_config/logs"
for d in specs admin scripts tests tools; do
  if [ -d "$SRC/1_agentic_config/$d" ]; then cp -r "$SRC/1_agentic_config/$d" "$DST/1_agentic_config/$d"; fi
done

# Scrub per-vault SECRETS from shipped docs — real API keys must NEVER travel in a shared framework repo.
# Replaces any backtick-wrapped 32+ hex string (an API key) with a placeholder, keeping the doc structure.
find "$DST/1_agentic_config" -name '*.md' -exec \
  sed -i -E 's/`[0-9a-fA-F]{32,}`/`<paste your key locally; NEVER commit a real key to a shared repo>`/g' {} +

# --- .obsidian: shared config (minus workspace.json); plugin code minus data.json (key) ---
mkdir -p "$DST/.obsidian"
for f in app.json appearance.json community-plugins.json core-plugins.json daily-notes.json graph.json hotkeys.json types.json; do
  if [ -f "$SRC/.obsidian/$f" ]; then cp "$SRC/.obsidian/$f" "$DST/.obsidian/$f"; fi
done
if [ -d "$SRC/.obsidian/plugins" ]; then
  cp -r "$SRC/.obsidian/plugins" "$DST/.obsidian/plugins"
  find "$DST/.obsidian/plugins" -name data.json -delete
fi

# --- empty data-plane dirs with .gitkeep ---
for d in 2_using_timeline 3_generates_wiki/sources 3_generates_wiki/concepts \
         3_generates_wiki/entities 3_generates_wiki/synthesis 4_collaboration; do
  mkdir -p "$DST/$d"; touch "$DST/$d/.gitkeep"
done

# --- fresh logs hub ---
cat > "$DST/1_agentic_config/logs/_agent_logs.md" <<'EOF'
# Agent Logs

_Collection note for the append-only agent log, one file per calendar month. Newest month on top; each file is `YYYY-MM.md`._

**Conventions**
- Append-only: never edit past entries; corrections go in a new entry.
- One file per calendar month; create the next month's file on its first entry.
- Entry format and valid operations are defined in `AGENTS.md` -> Logging.

## Months

_(none yet -- the first logged operation creates this month's file and its line here.)_
EOF

# --- fresh zeroed wiki index ---
cat > "$DST/3_generates_wiki/wiki.index.md" <<'EOF'
# Wiki Index
_Last updated: (fresh vault) — 0 sources, 0 concepts, 0 entities, 0 synthesis pages_

---

## Sources
_(none yet — drop a file in `2_using_timeline/` and say "ingest <filename>".)_

## Concepts
_(none yet)_

## Entities
_(none yet)_

## Synthesis
_(none yet)_

## Meta
- [[checklist.new-wiki-project]] — bootstrap checklist (clone → push → setup)
- [[spec.git-ops]] — the two-remote (clone/upstream) multi-vault git model
- [[spec.testing]] — how to run the local test harnesses
- [[RUNBOOK.git-ops]] — break-glass recovery
- [[spec.directory-structure]] — annotated directory tree
- [[pattern.karpathy-llm-wiki]] — the founding pattern
EOF

# --- SECRET SAFETY GATE: never ship a skeleton with a key-looking string in the framework docs ---
if grep -rInE '`[0-9a-fA-F]{32,}`' "$DST/1_agentic_config" "$DST/AGENTS.md" 2>/dev/null; then
  echo "" >&2
  echo "‼ ABORT: possible secret (32+ hex) still present in the skeleton (listed above). Do NOT ship. Scrub the source and rebuild." >&2
  exit 1
fi

echo "skeleton built at $DST (from $SRC)"
