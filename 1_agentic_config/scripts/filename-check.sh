#!/usr/bin/env bash
#
# filename-check.sh — the canonical definition of "bad" characters for files
# entering user.timeline/. This is MINIMAL SANITIZATION, not slugification:
# it preserves spaces, parentheses, ampersands, double-hyphens, and original
# casing — everything that keeps the name human-readable and exact-match
# [[wikilinkable]] in Obsidian. It flags ONLY characters that break Obsidian
# wikilinks or the filesystem.
#
# Usage:  filename-check.sh "Some Clipped Title (v2).md"
# Exit:   0 = clean | 1 = must-fix present | 2 = recommend-fix only | 64 = usage
#
# Referenced by AGENTS.md ingest step 1b. Change the rules in ONE place: the
# two arrays below.

set -u

name="${1:-}"
[[ -z "$name" ]] && { echo "usage: filename-check.sh <filename>" >&2; exit 64; }

# MUST-FIX: break Obsidian [[wikilinks]] or the filesystem. A file containing
# any of these cannot be cleanly wikilinked as-is.
must_chars=( '[' ']' '|' '#' '^' '\' '/' )
# RECOMMEND-FIX: legal on Linux, but illegal on Windows or hazardous in bash.
rec_chars=( ':' '*' '?' '"' '<' '>' )

found_must=()
for c in "${must_chars[@]}"; do
  [[ "$name" == *"$c"* ]] && found_must+=( "$c" )
done
found_rec=()
for c in "${rec_chars[@]}"; do
  [[ "$name" == *"$c"* ]] && found_rec+=( "$c" )
done

# A leading - or . is also hazardous (looks like a flag to bash / hidden file).
lead_flag=""
[[ "$name" == -* || "$name" == .* ]] && lead_flag="yes"

echo "ORIGINAL: $name"

if (( ${#found_must[@]} == 0 )) && (( ${#found_rec[@]} == 0 )) && [[ -z "$lead_flag" ]]; then
  echo "STATUS: clean"
  exit 0
fi

# Build a proposed minimal-fix name: replace ONLY flagged chars with '-',
# preserve everything else (spaces, parens, &, --, case) verbatim.
proposed="$name"
for c in "${must_chars[@]}"; do proposed="${proposed//"$c"/-}"; done
for c in "${rec_chars[@]}";  do proposed="${proposed//"$c"/-}"; done
proposed="${proposed#[-.]}"                                   # drop one leading - or .
proposed="${proposed#"${proposed%%[![:space:]]*}"}"          # ltrim whitespace
proposed="${proposed%"${proposed##*[![:space:]]}"}"          # rtrim whitespace

(( ${#found_must[@]} )) && echo "MUST_FIX_CHARS: ${found_must[*]}"
(( ${#found_rec[@]} ))  && echo "RECOMMEND_CHARS: ${found_rec[*]}"
[[ -n "$lead_flag" ]]   && echo "LEADING_FLAG: yes"
echo "PROPOSED: $proposed"

if (( ${#found_must[@]} )); then
  echo "STATUS: must-fix"
  exit 1
fi
echo "STATUS: recommend-fix"
exit 2
