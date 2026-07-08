#!/usr/bin/env bash
# run-all.sh — run every framework test harness against the actual shipped
# artifacts. Fully local (throwaway git repos / localhost HTTP in $TMPDIR); needs
# only `git`, `python3`, and bash. No GitHub, no Obsidian. Exit 0 = all green.
# See spec.testing.md for what each proves.
HERE=$(cd "$(dirname "$0")" && pwd)
fail=0
for t in test-hook test-setup test-workflow test-doctor test-localizer test-guard; do
  echo "######## $t ########"
  bash "$HERE/$t.sh" || fail=1
  echo
done
if [ $fail -eq 0 ]; then echo "✅ ALL HARNESSES PASSED"; else echo "❌ SOME HARNESSES FAILED"; exit 1; fi
