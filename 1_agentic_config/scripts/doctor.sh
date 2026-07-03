#!/usr/bin/env bash
# doctor.sh — health check for an agentic-KB clone.
#
# THE key check: is any *tracked* file knowledge-base CONTENT? In a framework /
# gateway clone that means a contamination slip — the thing that unfreezes the
# shared framework and breaks pulls for every vault. Also reports hook + remotes.
#
# Content patterns come from the SAME single-source-of-truth manifest the
# pre-commit hook uses: 1_agentic_config/scripts/content-paths.
# Exit 0 = healthy, 1 = problem, 2 = not a repo.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "doctor: not in a git repo"; exit 2; }
cd "$ROOT"
MANIFEST="1_agentic_config/scripts/content-paths"

echo "== agentic-KB doctor =="
echo "core.hooksPath: $(git config --get core.hooksPath || echo '(unset)')"
echo "remotes:"; git remote -v 2>/dev/null | sed 's/^/  /'

problems=0
if [ -f "$MANIFEST" ]; then
  mapfile -t PATTERNS < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST")
  contam=()
  while IFS= read -r f; do
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    for pat in "${PATTERNS[@]}"; do
      if [[ "$f" == $pat ]]; then contam+=("$f"); break; fi
    done
  done < <(git ls-files)
  if [ ${#contam[@]} -gt 0 ]; then
    echo "PROBLEM: knowledge-base CONTENT is tracked in this clone:"
    printf '    %s\n' "${contam[@]}"
    echo "  If this is the framework/gateway repo, this is a contamination slip. Recover:"
    echo "    git rm -r --cached <paths above> && git commit -m 'recover: remove content' && git push"
    echo "  Full procedure: 1_agentic_config/admin/RUNBOOK.git-ops.md"
    problems=$((problems + 1))
  else
    echo "content check: clean (no knowledge-base content tracked)"
  fi
else
  echo "content check: SKIPPED (no content-paths manifest found)"
fi

if [ $problems -eq 0 ]; then echo "HEALTHY"; exit 0; else echo "$problems problem(s) found"; exit 1; fi
