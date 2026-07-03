#!/usr/bin/env bash
# test-workflow.sh — end-to-end fork/upstream workflow on LOCAL bare repos.
# Proves: content backs up to the vault's own origin; a framework fix pulled from
# upstream preserves the vault's content; the framework repo never receives content.
# Tests the ACTUAL shipped hook/manifest/setup.sh. No GitHub/Obsidian.
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)
pass=0; fail=0
check(){ if [ "$2" = "$3" ]; then printf '  PASS  %-48s\n' "$1"; pass=$((pass+1));
         else printf '  FAIL  %-48s got[%s] want[%s]\n' "$1" "$2" "$3"; fail=$((fail+1)); fi; }
echo "=== two-remote fork/upstream workflow ==="
ROOT=$(mktemp -d); cd "$ROOT"
export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@a GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@a

mkdir framework-src; cd framework-src; git init -q -b main; git config commit.gpgsign false
mkdir -p .githooks 1_agentic_config/scripts 1_agentic_config/logs 1_agentic_config/specs \
         3_generates_wiki/concepts 3_generates_wiki/sources 2_using_timeline
cp "$FW/.githooks/pre-commit"                   .githooks/pre-commit; chmod +x .githooks/pre-commit
cp "$FW/1_agentic_config/scripts/content-paths" 1_agentic_config/scripts/content-paths
cp "$FW/setup.sh"                               setup.sh; chmod +x setup.sh
printf 'spec v1\n'              > 1_agentic_config/specs/spec.sample.md
printf '# Wiki Index\n(seed)\n' > 3_generates_wiki/wiki.index.md
printf '# Agent Logs (seed)\n'  > 1_agentic_config/logs/_agent_logs.md
touch 2_using_timeline/.gitkeep 3_generates_wiki/concepts/.gitkeep 3_generates_wiki/sources/.gitkeep
git add -A; git commit -q -m "framework seed v1"; cd "$ROOT"

git clone -q --bare framework-src FW.git      # upstream (framework)
git clone -q --bare framework-src AS.git      # a fork (the vault's own repo)

git clone -q AS.git vault
( cd vault; git config commit.gpgsign false; git config pull.rebase false
  bash ./setup.sh --role vault --upstream "$ROOT/FW.git" >/dev/null )

( cd vault
  printf '# Nebula\nastro\n'               > 3_generates_wiki/concepts/nebula.md
  printf '# Wiki Index\n1 ASTRO-CONTENT\n' > 3_generates_wiki/wiki.index.md
  git add -A; git commit -q -m "ingest: nebula"; git push -q origin main )
check "backup: nebula pushed to own repo (AS.git)" \
      "$(git -C AS.git ls-tree -r --name-only main | grep -c 'concepts/nebula.md')" "1"

git clone -q FW.git gw
( cd gw; git config commit.gpgsign false
  bash ./setup.sh --role gateway >/dev/null
  printf 'spec v1\nFRAMEWORK-FIX-V2\n' > 1_agentic_config/specs/spec.sample.md
  git add -A; git commit -q -m "framework fix v2"; git push -q origin main )
check "framework fix landed in FW.git" \
      "$(git -C FW.git show main:1_agentic_config/specs/spec.sample.md | grep -c FRAMEWORK-FIX-V2)" "1"

( cd vault; git pull -q --no-rebase --no-edit upstream main )
check "vault received framework fix"                 "$(grep -c FRAMEWORK-FIX-V2 vault/1_agentic_config/specs/spec.sample.md)" "1"
check "vault KEPT content (nebula survives pull)"    "$([ -f vault/3_generates_wiki/concepts/nebula.md ] && echo 1 || echo 0)" "1"
check "vault KEPT wiki.index content (not reseeded)" "$(grep -c ASTRO-CONTENT vault/3_generates_wiki/wiki.index.md)" "1"
check "invariant: FW.git has NO vault content"       "$(git -C FW.git ls-tree -r --name-only main | grep -c 'concepts/nebula.md')" "0"
check "invariant: FW.git wiki.index still the seed"  "$(git -C FW.git show main:3_generates_wiki/wiki.index.md | grep -c ASTRO-CONTENT)" "0"

echo ""; echo "workflow: $pass passed, $fail failed."; [ $fail -eq 0 ]
