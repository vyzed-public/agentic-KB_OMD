#!/usr/bin/env bash
# PreToolUse hook: protects the timeline (2_using_timeline/). Blocks deletes/overwrites and
# Write/Edit into it, and moving files OUT. Moves WITHIN it (the ingest workflow) are allowed.

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // ""')

block() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

case "$tool" in

  Bash)
    command=$(echo "$input" | jq -r '.tool_input.command // ""')
    tl=$(echo "$command" | grep -oE '2_using_timeline/' | wc -l | tr -d ' ')
    # Always block delete/overwrite verbs touching the timeline.
    if [ "$tl" -ge 1 ] && echo "$command" | grep -qE '\b(rm|truncate|tee|dd|chmod)\b'; then
      block "2_using_timeline\/ delete\/overwrite is blocked. Claude may not delete or overwrite files there. Tell the user what you were trying to do and ask them to do it manually."
    fi
    # Allow mv/cp only WITHIN the timeline (path appears twice+); block moving a file OUT of it (appears once).
    if echo "$command" | grep -qE '\b(mv|cp)\b' && [ "$tl" -eq 1 ]; then
      block "Moving a file OUT of 2_using_timeline\/ is blocked. Moves WITHIN 2_using_timeline\/ are permitted (ingest workflow). Ask the user to do external moves manually."
    fi
    ;;

  Write)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    if echo "$file_path" | grep -qE '/2_using_timeline/[^/]'; then
      block "2_using_timeline\/ is immutable. Claude is not permitted to write files there. Tell the user what you were trying to do and ask them to do it manually."
    fi
    ;;

  Edit)
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')
    if echo "$file_path" | grep -qE '/2_using_timeline/[^/]'; then
      # --- Ingest-stamp carve-out (the ONLY agent Edit allowed on a CTN) ---
      # An Edit may add or change ONLY these four frontmatter fields:
      #     purpose:   projects:   repeat:   priority:
      # (plus projects:'s "  - " list items). The body, the --- fences, and
      # every OTHER frontmatter field stay blocked. An existing line used only
      # as an anchor (e.g. `created:`) is left UNCHANGED, so it is exempt --
      # this is what lets a brand-new clip get all four stamped in one Edit.
      old_string=$(echo "$input" | jq -r '.tool_input.old_string // ""')
      new_string=$(echo "$input" | jq -r '.tool_input.new_string // ""')

      # The CHANGED lines = lines added in new + lines removed from old.
      # (Lines identical in both are unchanged context/anchor -> not checked.)
      added=$(comm -13 <(printf '%s\n' "$old_string" | sort) <(printf '%s\n' "$new_string" | sort))
      removed=$(comm -23 <(printf '%s\n' "$old_string" | sort) <(printf '%s\n' "$new_string" | sort))
      changed=$(printf '%s\n%s\n' "$added" "$removed")

      # RULE 1: every changed line is blank, one of the four fields, or an
      #         indented "  - " list item / wrapped value.
      illegal=$(printf '%s\n' "$changed" \
        | grep -vE '^[[:space:]]*$|^(purpose|projects|repeat|priority):|^[[:space:]]+[^[:space:]]')

      # RULE 2: an indented (list/wrap) change is allowed ONLY when the edit
      #         also carries a `projects:` or `purpose:` line -- proving those
      #         items belong to OUR fields, not to another list field (related:).
      indent_change=$(printf '%s\n' "$changed" | grep -cE '^[[:space:]]+[^[:space:]]')
      parent_present=$(printf '%s\n%s\n' "$old_string" "$new_string" | grep -cE '^(projects|purpose):')

      if [ -z "$illegal" ] && { [ "$indent_change" -eq 0 ] || [ "$parent_present" -ge 1 ]; }; then
        exit 0   # edit is confined to purpose/projects/repeat/priority -- allow
      fi
      block "2_using_timeline\/ is immutable. On a CTN the only allowed Edit adds or changes the four ingest fields (purpose\/projects\/repeat\/priority); this edit changes the body, a --- fence, or another field. Do it manually."
    fi
    ;;

esac

exit 0
