#!/usr/bin/env bash
# PreToolUse hook: LOCATION-BASED timeline immutability for 2_using_timeline/.
#
# Two zones, decided purely by PATH (no content diffing):
#   STAGED  2_using_timeline/<file>          (top level, incl. attachments/)  -> agent-MUTABLE
#   FILED   2_using_timeline/YYYY/MM/...      (dated folders + their assets/)  -> agent-IMMUTABLE
# The one-way filing move (staged -> filed) SEALS a note. After that the agent
# may only READ it. Deletion is curator-only in BOTH zones.
#
#   stage  ->  stamp + localize (mutate freely)  ->  file (seal)  ->  generate
#
# Rules:
#   - delete-class verbs (rm/rmdir/unlink/shred/find -delete/git clean) touching
#     ANY timeline path        -> BLOCK (curator-only, everywhere)
#   - mv/cp that moves a path OUT of the timeline               -> BLOCK
#   - any WRITE vector targeting a FILED path (redirect >/>>, sed -i, tee, cp
#     dest, truncate, dd, chmod, an interpreter) -> BLOCK; the SOLE exception is
#     the filing SEAL: `mv <staged...> <filed-dest>`.
#   - STAGED paths: every write vector is ALLOWED (this replaces the old
#     content-diff carve-out — staging is the work zone; the seal is the lock).
#   - Read/ls/grep/cat of either zone: always ALLOWED.
#
# Blocking works ONLY via a JSON deny decision on stdout + exit 0 (exit 1 does
# NOT block — Claude Code treats it as a non-blocking error). Spec + rationale:
# spec.timeline-guard-hook.md. Pinned by tests/test-guard.sh.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // ""')

block() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# FILED iff the path enters a dated YYYY/MM folder under the timeline.
is_filed()   { echo "$1" | grep -qE '(^|/)2_using_timeline/[0-9]{4}/[0-9]{2}(/|$)'; }
is_timeline(){ echo "$1" | grep -qE '(^|/)2_using_timeline/'; }

case "$tool" in

  Bash)
    command=$(echo "$input" | jq -r '.tool_input.command // ""')
    # occurrences of any timeline path, and of the FILED subset
    tl=$(echo "$command"     | grep -oE '2_using_timeline/'                   | wc -l | tr -d ' ')
    [ "$tl" -eq 0 ] && exit 0                     # nothing to do with the timeline
    filed=$(echo "$command"  | grep -oE '2_using_timeline/[0-9]{4}/[0-9]{2}'  | wc -l | tr -d ' ')

    # (A) Deletion is curator-only EVERYWHERE (staged and filed alike).
    if echo "$command" | grep -qE '\b(rm|rmdir|unlink|shred)\b'; then
      block "Deleting from 2_using_timeline is curator-only. Claude may not delete files there in any zone. Tell the user what you were trying to do and ask them to do it manually."
    fi
    if echo "$command" | grep -qE 'find\b.*\b2_using_timeline\b.*-delete|\bgit\b.*\bclean\b'; then
      block "Bulk deletion in 2_using_timeline is curator-only. Ask the user to do it manually."
    fi

    # (B) Moving/copying a file OUT of the timeline (a single timeline path with
    #     mv/cp = source inside, destination elsewhere).
    if echo "$command" | grep -qE '\b(mv|cp|rsync|install)\b' && [ "$tl" -eq 1 ]; then
      block "Moving a file OUT of 2_using_timeline is blocked. Moves WITHIN it (the ingest/filing workflow) are allowed. Ask the user to do external moves manually."
    fi

    # (C) FILED immutability.
    if [ "$filed" -ge 1 ]; then
      # last timeline path referenced = the destination for mv/cp/redirect
      last=$(echo "$command" | grep -oE '2_using_timeline/[0-9]{4}/[0-9]{2}|2_using_timeline/' | tail -1)
      last_is_filed=0; [[ "$last" =~ 2_using_timeline/[0-9]{4}/[0-9]{2} ]] && last_is_filed=1
      staged=$((tl - filed))

      # The SOLE allowed touch of a filed path: the filing SEAL, mv staged->filed.
      # Recognized narrowly: an mv, exactly one filed path (the dest), >=1 staged
      # source, and that filed path is the LAST timeline token (the destination).
      if echo "$command" | grep -qE '\bmv\b' \
         && [ "$filed" -eq 1 ] && [ "$staged" -ge 1 ] && [ "$last_is_filed" -eq 1 ]; then
        exit 0                                     # filing seal — allow
      fi

      # Any OTHER mv/cp involving a filed path mutates the filed zone (filed->staged
      # un-file, filed->filed rename, cp into filed) -> block.
      if echo "$command" | grep -qE '\b(mv|cp)\b'; then
        block "2_using_timeline/YYYY/MM (a FILED note) is agent-immutable. Only the one-way filing move staged->filed is allowed; un-filing, filed renames, and copies into a filed folder are blocked. Ask the user to do it manually."
      fi

      # Write vectors aimed at a filed path: redirect, sed -i, tee, truncate, dd,
      # chmod, or any interpreter reaching into the filed zone.
      if echo "$command" | grep -qE '(>>?|>\|)[[:space:]]*"?'\''?2_using_timeline/[0-9]{4}/[0-9]{2}'; then
        block "Redirecting output into a FILED note (2_using_timeline/YYYY/MM) is blocked — filed notes are agent-immutable. Ask the user to do it manually."
      fi
      if echo "$command" | grep -qE '\bsed\b[^|]*-i' \
         || echo "$command" | grep -qE '\btee\b' \
         || echo "$command" | grep -qE '\b(truncate|dd|chmod)\b' \
         || echo "$command" | grep -qE '\b(python3?|perl|ruby|node|awk)\b'; then
        block "That command writes into (or runs code over) a FILED note in 2_using_timeline/YYYY/MM, which is agent-immutable. Read filed notes with the Read tool; ask the user for any change."
      fi
      # otherwise it only READS the filed path (cat/grep/ls/head/…) -> allow
    fi

    # (D) Staged-only writes fall through -> allowed (the work zone).
    ;;

  Write)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    if is_timeline "$file_path"; then
      if is_filed "$file_path"; then
        block "2_using_timeline/YYYY/MM (a FILED note) is agent-immutable — Claude cannot write there. Tell the user what you were trying to do and ask them to do it manually."
      fi
      # STAGED write is allowed (localize/stage work zone) -> fall through
    fi
    ;;

  Edit)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    if is_timeline "$file_path"; then
      if is_filed "$file_path"; then
        block "2_using_timeline/YYYY/MM (a FILED note) is agent-immutable — Claude cannot edit there. A note is sealed once filed. Ask the user to do it manually."
      fi
      # STAGED edit is allowed (stamp intent fields + localize happen here) ->
      # fall through. This replaces the old four-field content-diff carve-out.
    fi
    ;;

esac

exit 0
