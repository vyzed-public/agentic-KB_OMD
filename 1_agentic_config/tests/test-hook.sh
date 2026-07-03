#!/usr/bin/env bash
# test-hook.sh — verify the content-guard pre-commit hook blocks knowledge-base
# CONTENT from being committed, while allowing framework files, .gitkeep, and the
# two seed files. Tests the ACTUAL shipped hook + manifest. Local only (throwaway
# git repo); no GitHub, no Obsidian. Run: bash 1_agentic_config/tests/test-hook.sh
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)     # framework repo root
pass=0; fail=0
R=$(mktemp -d); cd "$R" || exit 1
git init -q; git config user.email t@t.t; git config user.name tester; git config commit.gpgsign false
mkdir -p .githooks 1_agentic_config/scripts 1_agentic_config/specs 1_agentic_config/logs \
         3_generates_wiki/concepts 3_generates_wiki/sources 3_generates_wiki/entities 2_using_timeline
cp "$FW/.githooks/pre-commit" .githooks/pre-commit && chmod +x .githooks/pre-commit
cp "$FW/1_agentic_config/scripts/content-paths" 1_agentic_config/scripts/content-paths
printf '# spec\n' > 1_agentic_config/specs/spec.sample.md
printf '# index\n' > 3_generates_wiki/wiki.index.md
printf '# hub\n' > 1_agentic_config/logs/_agent_logs.md
touch 2_using_timeline/.gitkeep 3_generates_wiki/sources/.gitkeep
git add -A && git commit -q -m baseline
git config core.hooksPath .githooks
run(){ local desc="$1" expect="$2" stage="$3"; eval "$stage"
  git commit -q -m t >/dev/null 2>&1; local rc=$?; local got=allow; [ $rc -ne 0 ] && got=deny
  if [ "$got" = "$expect" ]; then printf '  PASS  %-50s (%s)\n' "$desc" "$got"; pass=$((pass+1))
  else printf '  FAIL  %-50s expected %s got %s\n' "$desc" "$expect" "$got"; fail=$((fail+1)); fi
  git reset -q --hard >/dev/null 2>&1; git clean -fdq >/dev/null 2>&1; }
echo "=== content-guard pre-commit hook ==="
run "framework file (spec)"           allow 'echo x >> 1_agentic_config/specs/spec.sample.md; git add -A'
run "content: generated concept page" deny  'mkdir -p 3_generates_wiki/concepts; echo x > 3_generates_wiki/concepts/blackhole.md; git add -A'
run "content: ingested timeline note" deny  'mkdir -p 2_using_timeline/2026/07; echo x > "2_using_timeline/2026/07/note.md"; git add -A'
run ".gitkeep under a content dir"    allow 'mkdir -p 3_generates_wiki/entities; echo "" > 3_generates_wiki/entities/.gitkeep; git add -A'
run "content: monthly log file"       deny  'echo x > 1_agentic_config/logs/2026-07.md; git add -A'
run "seed: wiki.index.md (allowed)"   allow 'echo x >> 3_generates_wiki/wiki.index.md; git add -A'
run "seed: _agent_logs.md (allowed)"  allow 'echo x >> 1_agentic_config/logs/_agent_logs.md; git add -A'
run "MIXED: framework + content"      deny  'echo x >> 1_agentic_config/specs/spec.sample.md; mkdir -p 3_generates_wiki/sources; echo x > 3_generates_wiki/sources/paper.md; git add -A'
echo ""; echo "hook: $pass passed, $fail failed."; rm -rf "$R"; [ $fail -eq 0 ]
