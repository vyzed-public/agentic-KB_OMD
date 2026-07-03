#!/usr/bin/env bash
# test-doctor.sh — verify doctor.sh detects a contamination slip (content committed
# into a framework/gateway clone) and confirms clean after recovery. Tests the ACTUAL
# shipped doctor.sh. Local only. Run: bash 1_agentic_config/tests/test-doctor.sh
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)
pass=0; fail=0
check(){ if [ "$2" = "$3" ]; then printf '  PASS  %-44s\n' "$1"; pass=$((pass+1));
         else printf '  FAIL  %-44s got[%s] want[%s]\n' "$1" "$2" "$3"; fail=$((fail+1)); fi; }
export GIT_AUTHOR_NAME=a GIT_AUTHOR_EMAIL=a@a GIT_COMMITTER_NAME=a GIT_COMMITTER_EMAIL=a@a
echo "=== doctor.sh detection + recovery ==="
R=$(mktemp -d); cd "$R"; git init -q -b main; git config commit.gpgsign false
mkdir -p .githooks 1_agentic_config/scripts 1_agentic_config/specs 3_generates_wiki/concepts
cp "$FW/1_agentic_config/scripts/content-paths" 1_agentic_config/scripts/content-paths
cp "$FW/1_agentic_config/scripts/doctor.sh"     doctor.sh; chmod +x doctor.sh
cp "$FW/.githooks/pre-commit"                   .githooks/pre-commit; chmod +x .githooks/pre-commit
printf 'spec\n' > 1_agentic_config/specs/s.md
git add -A; git commit -q -m base
git config core.hooksPath .githooks
bash ./doctor.sh >/dev/null 2>&1; check "healthy clone -> exit 0" "$?" "0"
echo x > 3_generates_wiki/concepts/leak.md
git add -A && git commit -q --no-verify -m "OOPS content leak"
bash ./doctor.sh >/dev/null 2>&1; check "detects contamination -> exit 1" "$?" "1"
if bash ./doctor.sh 2>&1 | grep -q 'concepts/leak.md'; then r=0; else r=1; fi
check "names the leaked file" "$r" "0"
git rm -q --cached 3_generates_wiki/concepts/leak.md >/dev/null; rm -f 3_generates_wiki/concepts/leak.md
git commit -q --no-verify -m "recover"
bash ./doctor.sh >/dev/null 2>&1; check "clean after recovery -> exit 0" "$?" "0"
echo ""; echo "doctor: $pass passed, $fail failed."; [ $fail -eq 0 ]
