#!/usr/bin/env bash
# test-guard.sh — pin the LOCATION-BASED timeline guard. Feeds crafted PreToolUse
# payloads to the ACTUAL shipped hook and asserts allow/deny for every write
# vector across both zones (STAGED = mutable, FILED = immutable, delete =
# curator-only everywhere, filing seal = the one allowed staged->filed move).
# Local only; needs jq + bash. Run: bash 1_agentic_config/tests/test-guard.sh
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)
GUARD="$FW/1_agentic_config/scripts/timeline-guard.sh"
pass=0; fail=0

verdict(){ # $1 payload-json -> prints "deny" or "allow"
  local out; out=$(printf '%s' "$1" | bash "$GUARD" 2>/dev/null)
  if echo "$out" | grep -q '"permissionDecision":"deny"'; then echo deny; else echo allow; fi
}
b(){ # bash-command test: desc expect cmd
  local desc="$1" expect="$2" cmd="$3"
  local pl; pl=$(jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  local got; got=$(verdict "$pl")
  if [ "$got" = "$expect" ]; then printf '  PASS  %-46s (%s)\n' "$desc" "$got"; pass=$((pass+1))
  else printf '  FAIL  %-46s expected %s got %s\n' "$desc" "$expect" "$got"; fail=$((fail+1)); fi
}
p(){ # path test (Write/Edit): tool desc expect path
  local tool="$1" desc="$2" expect="$3" path="$4"
  local pl; pl=$(jq -nc --arg t "$tool" --arg f "$path" '{tool_name:$t,tool_input:{file_path:$f}}')
  local got; got=$(verdict "$pl")
  if [ "$got" = "$expect" ]; then printf '  PASS  %-46s (%s)\n' "$desc" "$got"; pass=$((pass+1))
  else printf '  FAIL  %-46s expected %s got %s\n' "$desc" "$expect" "$got"; fail=$((fail+1)); fi
}

F='2_using_timeline/2026/07'   # a FILED location
S='2_using_timeline'           # STAGED (top level)

echo "=== location-based timeline guard ==="

echo "-- reads (both zones) allowed --"
b "cat a filed note"            allow "cat $F/note.md"
b "grep a filed note"           allow "grep foo $F/note.md"
b "ls a filed dir"              allow "ls $F/"
b "read filed, write staged"    allow "cat $F/old.md > $S/new.md"
b "command not touching timeline" allow "ls /tmp && echo hi"

echo "-- staged zone is mutable --"
b "redirect into staged"        allow "echo x > $S/note.md"
b "append into staged"          allow "echo x >> $S/note.md"
b "sed -i a staged note"        allow "sed -i s/a/b/ $S/note.md"
b "localize a staged note"      allow "python3 $FW/1_agentic_config/scripts/attachment-localize.py $S/note.md $S/attachments/"
b "rename within staging"       allow "mv $S/bad.md $S/good.md"

echo "-- the filing SEAL (staged -> filed) allowed --"
b "file a note (seal)"          allow "mv $S/note.md $F/note.md"
b "file a note w/ spaces->dir"  allow "mv \"$S/AI 2027 (x).md\" $F/"
b "file an asset (seal)"        allow "mv $S/attachments/img.png $F/assets/img.png"

echo "-- deletion is curator-only EVERYWHERE --"
b "rm a staged note"            deny  "rm $S/note.md"
b "rm a filed note"             deny  "rm $F/note.md"
b "shred a filed note"          deny  "shred $F/note.md"
b "find -delete in timeline"    deny  "find $S/ -name '*.md' -delete"
b "git clean the timeline"      deny  "git clean -fdx $S/"

echo "-- moving OUT of the timeline blocked --"
b "mv a staged note out"        deny  "mv $S/note.md /tmp/x.md"
b "mv a filed note out"         deny  "mv $F/note.md /tmp/x.md"

echo "-- FILED zone is immutable (every write vector) --"
b "un-file (filed -> staged)"   deny  "mv $F/note.md $S/note.md"
b "rename within filed"         deny  "mv $F/a.md $F/b.md"
b "cp INTO a filed folder"      deny  "cp $S/attachments/x.png $F/assets/x.png"
b "redirect into filed"         deny  "echo x > $F/note.md"
b "append into filed"           deny  "echo x >> $F/note.md"
b "sed -i a filed note"         deny  "sed -i s/a/b/ $F/note.md"
b "tee into a filed note"       deny  "cat x | tee $F/note.md"
b "truncate a filed note"       deny  "truncate -s0 $F/note.md"
b "chmod a filed note"          deny  "chmod 644 $F/note.md"
b "run python over a filed note" deny "python3 munge.py $F/note.md"

echo "-- Write / Edit tools by location --"
p Write "Write into staged"     allow "/home/u/vault/$S/note.md"
p Write "Write into filed"      deny  "/home/u/vault/$F/note.md"
p Write "Write outside timeline" allow "/home/u/vault/3_generates_wiki/x.md"
p Edit  "Edit a staged note"    allow "/home/u/vault/$S/note.md"
p Edit  "Edit a filed note"     deny  "/home/u/vault/$F/note.md"
p Edit  "Edit outside timeline" allow "/home/u/vault/3_generates_wiki/x.md"

echo ""; echo "guard: $pass passed, $fail failed."
[ $fail -eq 0 ]
