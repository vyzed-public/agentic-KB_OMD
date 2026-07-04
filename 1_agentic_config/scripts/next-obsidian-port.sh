#!/usr/bin/env bash
# next-obsidian-port.sh — report which Obsidian Local REST API ports are already
# in use on this host, and suggest the next free one, so a new vault never
# collides. You do NOT have to remember what you assigned before.
#
# Source of truth: the Claude Code MCP registrations in ~/.claude.json — every
# vault must be registered there to work, so it is the durable record of every
# port ever assigned. Augmented (best-effort) by ports currently LISTENING, which
# catches a vault that is open but not yet registered. Read-only; changes nothing.
#
# Usage:  bash 1_agentic_config/scripts/next-obsidian-port.sh
set -euo pipefail

BASE=27124                                   # first Obsidian port, by convention
CFG="${CLAUDE_CONFIG:-$HOME/.claude.json}"

# --- ports registered as MCP servers on 127.0.0.1 (the durable registry) ---
registered_ports() {
  [ -f "$CFG" ] || return 0
  python3 - "$CFG" <<'PY' 2>/dev/null || true
import json, re, sys
try:
    cfg = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
def walk(o):
    if isinstance(o, dict):
        if isinstance(o.get("mcpServers"), dict):
            for srv in o["mcpServers"].values():
                url = (srv or {}).get("url", "") if isinstance(srv, dict) else ""
                m = re.search(r'127\.0\.0\.1:(\d+)', url or "")
                if m:
                    print(m.group(1))
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)
walk(cfg)
PY
}

# --- ports in the Obsidian band currently LISTENING (best-effort) ---
listening_ports() {
  command -v ss >/dev/null 2>&1 || return 0
  ss -ltnH 2>/dev/null | grep -oE '127\.0\.0\.1:271[0-9][0-9]' | grep -oE '271[0-9][0-9]' || true
}

used=$( { registered_ports; listening_ports; } | grep -E '^[0-9]+$' | sort -un || true )

echo "Obsidian ports in use on this host:"
if [ -n "$used" ]; then
  echo "$used" | sed 's/^/  - /'
else
  echo "  (none found — this looks like the first vault)"
fi

# first free port at or above BASE (fills gaps)
p=$BASE
while printf '%s\n' "$used" | grep -qx "$p"; do p=$((p+1)); done

echo
echo "Next free port: $p"
echo "  → set this vault's plugin port to $p, then register with:"
echo "    claude mcp add --transport http obsidian-<name> https://127.0.0.1:$p/mcp/ --header \"Authorization: Bearer <KEY>\" -s user"
