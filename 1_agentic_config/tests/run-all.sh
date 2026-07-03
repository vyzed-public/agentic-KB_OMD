#!/usr/bin/env bash
# run-all.sh — run every git-ops test harness against the actual shipped framework
# artifacts. Fully local (throwaway git repos in $TMPDIR); needs only `git` + bash.
# No GitHub, no Obsidian. Exit 0 = all green. See spec.testing.md for what each proves.
HERE=$(cd "$(dirname "$0")" && pwd)
fail=0
for t in test-hook test-setup test-workflow test-doctor; do
  echo "######## $t ########"
  bash "$HERE/$t.sh" || fail=1
  echo
done
if [ $fail -eq 0 ]; then echo "✅ ALL GIT-OPS HARNESSES PASSED"; else echo "❌ SOME HARNESSES FAILED"; exit 1; fi
