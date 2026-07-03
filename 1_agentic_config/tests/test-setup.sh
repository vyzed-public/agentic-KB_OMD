#!/usr/bin/env bash
# test-setup.sh — verify setup.sh wires remotes + activates the hook per role.
# Tests the ACTUAL shipped setup.sh. Local only. Run: bash 1_agentic_config/tests/test-setup.sh
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)
pass=0; fail=0
check(){ if [ "$2" = "$3" ]; then printf '  PASS  %-40s\n' "$1"; pass=$((pass+1));
         else printf '  FAIL  %-40s got[%s] want[%s]\n' "$1" "$2" "$3"; fail=$((fail+1)); fi; }
echo "=== setup.sh (role-aware remotes + hook activation) ==="
UPDIR=$(mktemp -d); git init -q --bare "$UPDIR/framework.git"; UPURL="$UPDIR/framework.git"
scaffold(){ cd "$1"; git init -q -b main
  git config user.email a@a; git config user.name a; git config commit.gpgsign false
  mkdir -p .githooks 1_agentic_config/scripts 3_generates_wiki/concepts
  cp "$FW/setup.sh" setup.sh; chmod +x setup.sh
  cp "$FW/.githooks/pre-commit" .githooks/pre-commit; chmod +x .githooks/pre-commit
  cp "$FW/1_agentic_config/scripts/content-paths" 1_agentic_config/scripts/content-paths
  echo x > f.md; git add -A; git commit -q -m base; }
V=$(mktemp -d); scaffold "$V"
bash ./setup.sh --role vault --upstream "$UPURL" >/dev/null
check "vault: upstream fetch url"       "$(git remote get-url upstream 2>/dev/null)"        "$UPURL"
check "vault: upstream push DISABLED"   "$(git remote get-url --push upstream 2>/dev/null)" "DISABLED"
check "vault: hook NOT activated"       "$(git config --get core.hooksPath 2>/dev/null || echo NONE)" "NONE"
G=$(mktemp -d); scaffold "$G"
bash ./setup.sh --role gateway >/dev/null
check "gateway: hooksPath activated"    "$(git config --get core.hooksPath 2>/dev/null || echo NONE)" ".githooks"
echo y > 3_generates_wiki/concepts/x.md; git add -A
if git commit -q -m t >/dev/null 2>&1; then r=allow; else r=deny; fi
check "gateway: content commit blocked" "$r" "deny"
V2=$(mktemp -d); scaffold "$V2"
if bash ./setup.sh --role vault >/dev/null 2>&1; then r=ok; else r=err; fi
check "vault without --upstream errors" "$r" "err"
echo ""; echo "setup: $pass passed, $fail failed."; [ $fail -eq 0 ]
