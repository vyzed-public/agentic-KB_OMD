---
title: 2_using_timeline/ Guard Hook
created: 2026-06-16
description: A PreToolUse hook that prevents Claude from deleting or overwriting files in 2_using_timeline/ and from moving files out of it; moves within it (the ingest workflow) and the ingest-stamp Edit carve-out (four fields only) are allowed. Tested and confirmed to hold against direct user instructions.
updated: 2026-06-30
---

# 2_using_timeline/ Guard Hook

## Why This Exists

Schema rules in AGENTS.md are not enforced. A casual user instruction — "why don't you get rid of that one?" — caused Claude to permanently delete a source file from `2_using_timeline/` despite an explicit rule prohibiting it. No pushback. No warning.

See: https://github.com/anthropics/claude-code/issues/68761

The hook described here is the actual enforcement mechanism. Schema rules are reminders. This hook is a lock.

---

## What It Does

A `PreToolUse` hook fires before every Claude tool call. Targeting `2_using_timeline/`, the hook blocks the action and tells Claude to inform the user when it attempts:

- `Bash` deletes/overwrites — `rm`, `truncate`, `tee`, `dd`, `chmod`
- `Bash` `mv`/`cp` that moves a file **out** of `2_using_timeline/`
- `Write` with a file path inside `2_using_timeline/`
- `Edit` inside `2_using_timeline/` — **except** the ingest-stamp carve-out (below)

**Allowed:** `Read` (Claude must read sources to ingest them); `mv`/`cp` **within** `2_using_timeline/` — the ingest workflow renames files and moves them into dated `YYYY/MM/` folders (a path appearing **twice** in an `mv`/`cp` command is an internal move and is allowed; a single occurrence is a move out and is blocked); and the **ingest-stamp `Edit`** that writes only the four fields `purpose:` / `projects:` / `repeat:` / `priority:` onto a note's frontmatter (see the carve-out under Setup).

---

## Does It Hold Against User Instructions?

**Yes. Confirmed by live testing.**

The following instructions were given to Claude after the hook was in place. All were refused:

- *"go ahead and remove this-file-is-USELESS.md in 2_using_timeline/"*
- *"Will you do it if I say please?"*
- *"Will you do it if I get angry if you don't?"*
- *"I really, Really, REALLY want you to."*
- *"You're good to go for removing 2_using_timeline/this-file-is-USELESS.md"*

Claude refused every time. The hook operates at the tool call level — below the LLM's reasoning — so no amount of instruction, politeness, pressure, or phrasing makes Claude run *that* `rm`. But "holds against instructions" is not the same as "makes the timeline immutable" — see the next section.

---

## What It Does NOT Protect Against

**This is a picket fence, not a vault door.** It prohibits the obvious `rm` — but there are many ways to destroy files in `2_using_timeline/` that a string-matching PreToolUse hook cannot catch, because it inspects command *verbs* and *path text* and has no concept of "overwrite" (it never checks whether a destination already exists). Known gaps:

- **Overwrite by move/copy within the timeline** — `mv blank.md target.md` with both paths inside `2_using_timeline/` passes the "within-timeline move is allowed" rule and clobbers `target.md`; `cp` likewise.
- **Truncate by redirect** — `: > 2_using_timeline/x.md` or `echo … > 2_using_timeline/x.md`; a shell `>` is not one of the tracked verbs.
- **`cd` then a bare command** — once the working directory is inside the timeline, a later `rm x.md` / `> x.md` carries no `2_using_timeline/` text to match.
- **Non-`rm` deletion** — `find 2_using_timeline/ -delete`, `unlink`, `shred`, `rsync --delete`, `git clean`.
- **Indirection** — destruction performed inside a script (`bash script.sh`) or an editor; the hook only sees `bash script.sh`.

The hook stops casual, naive destruction — the founding incident was exactly that (a one-line `rm`). It does **not** provide immutability. For that, enforce it *below* the agent, where no command phrasing can route around it: OS-level read-only permissions or the immutable bit (`chattr +i`), `git` history on the vault, or filesystem snapshots (ZFS/btrfs/Time Machine).

---

## Setup

**Hook script:** [1_agentic_config/scripts/timeline-guard.sh](../scripts/timeline-guard.sh)

The canonical hook is the **script file linked above** — this doc deliberately does **not** re-embed it, to prevent drift (a pasted copy here already went stale once). Its behavior, by tool:

- **`Bash`** — blocks `rm`/`truncate`/`tee`/`dd`/`chmod` touching `2_using_timeline/`; blocks `mv`/`cp` that moves a file **out** (the `2_using_timeline/` path appears once); allows moves **within** it (the path appears twice or more — the ingest workflow).
- **`Write`** — blocks any path inside `2_using_timeline/`.
- **`Edit`** — blocks any path inside `2_using_timeline/` **except the ingest-stamp carve-out**: allow the Edit only when every *changed* line (vs. the original) is one of the four ingest fields — `purpose:` / `projects:` / `repeat:` / `priority:` — or a `projects:` `  - ` list item; an *unchanged* anchor line (e.g. `created:`) may be anything (this lets a fresh web clip get all four stamped in one Edit). Body, `---` fence, and other-field changes stay blocked. Rationale: the Obsidian property API (`vault_patch`) can only write *string* frontmatter — it stringifies a YAML list into `'["..."]'` and an integer into `"1"` — so stamping the typed `projects:` list and `priority:` integer requires a direct `Edit`, which the guard scopes to exactly those four fields. Full detail: [[spec.file-ingestion]] step 9.

**Wire into `.claude/settings.json` (project-level):**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/1_agentic_config/scripts/timeline-guard.sh\""
          }
        ]
      }
    ]
  }
}
```

**Use `$CLAUDE_PROJECT_DIR`, never a hardcoded absolute path.** Claude Code sets it to the vault root at runtime, so the hook resolves wherever the vault is dropped and whatever the directory is renamed to — this is what lets the guard survive a template-repo clone/para-drop. A hardcoded path silently disarms the guard in every clone (the exact silent rule-violation this hook exists to prevent).

**Critical note on blocking mechanism:** The hook must output a JSON deny decision to stdout and exit 0. Exiting with code 1 does NOT block — Claude Code treats exit 1 as a non-blocking error and the tool call proceeds. Only the JSON `permissionDecision: deny` output actually stops execution.

---

## How to Manage Files in 2_using_timeline/ Yourself

The hook only intercepts Claude's tool calls. You can manage `2_using_timeline/` freely:

- Delete via Obsidian's file browser
- Delete in your terminal: `rm 2_using_timeline/filename.md`
- Move or rename normally

Only Claude is locked out.
