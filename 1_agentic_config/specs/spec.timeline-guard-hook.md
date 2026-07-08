---
title: 2_using_timeline/ Guard Hook
created: 2026-06-16
description: A PreToolUse hook enforcing LOCATION-BASED timeline immutability. Two zones by path — STAGED (top-level 2_using_timeline/, agent-mutable) and FILED (2_using_timeline/YYYY/MM/, agent-immutable). The one-way filing move seals a note; deletion is curator-only in both zones. Tested and confirmed to hold against direct user instructions.
updated: 2026-07-06
---

# 2_using_timeline/ Guard Hook

## Why This Exists

Schema rules in AGENTS.md are not enforced. A casual user instruction — "why don't you get rid of that one?" — caused Claude to permanently delete a source file from `2_using_timeline/` despite an explicit rule prohibiting it. No pushback. No warning.

See: https://github.com/anthropics/claude-code/issues/68761

The hook described here is the actual enforcement mechanism. Schema rules are reminders. This hook is a lock.

---

## What It Does

The guard is **location-based**: a note's mutability is decided by *where it lives*, not by diffing what changed. Two zones under `2_using_timeline/`:

- **STAGED** — top level (`2_using_timeline/<file>`, including the `attachments/` staging dir). **Agent-mutable.** This is the ingest work zone: the agent stamps intent frontmatter and localizes attachments here freely.
- **FILED** — dated folders (`2_using_timeline/YYYY/MM/…` and their `assets/`). **Agent-immutable.** The one-way filing move `staged → filed` **seals** the note; afterward the agent may only *read* it.

```
stage  →  stamp + localize (mutate freely)  →  file (SEAL)  →  generate
```

A `PreToolUse` hook fires before every Claude tool call; when it blocks, it tells Claude to inform the user. It blocks:

- **Deletion in *either* zone** — `rm`/`rmdir`/`unlink`/`shred`, `find … -delete`, `git clean`. **Deletion is curator-only, everywhere.**
- **`mv`/`cp` that moves a file *out* of `2_using_timeline/`.**
- **Any write vector aimed at a FILED note** — redirect (`>`/`>>`), `sed -i`, `tee`, `truncate`, `dd`, `chmod`, `cp` into a filed folder, an interpreter (`python`/`perl`/`ruby`/`node`/`awk`) run over a filed path, or a `Write`/`Edit` tool call with a filed path.
- **Filed-zone `mv`** other than the seal — un-filing (`filed → staged`) and filed-to-filed renames.

**Allowed:** `Read`, and all reads via Bash (`cat`/`grep`/`ls`/…) in either zone; **every write vector on a STAGED path** (`Write`/`Edit`/redirect/`sed -i`/the localizer/rename-within-staging); and the **filing seal** — an `mv` whose source is staged and whose destination is a filed `YYYY/MM/` location.

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

**This is a picket fence, not a vault door.** It inspects command *verbs* and *path text*; a determined route-around still exists. What the location model **does** close (vs. the old verb-only guard): redirect/`sed -i`/`tee`/`truncate`/interpreter writes into a **FILED** note are now blocked (previously a `>` slipped through), and non-`rm` deletion (`find … -delete`, `unlink`, `shred`, `git clean`) is blocked in **both** zones. Remaining gaps:

- **The STAGED zone is *intentionally* wide open.** It is the mutable work zone, so `mv blank.md target.md`, `> target.md`, etc. on a top-level `2_using_timeline/` file all pass **by design**. A staged note is protected only *after* it's filed (the seal). Protection of the curator's original therefore depends on filing promptly — a staged note is not yet sealed.
- **`cd` then a bare command** — once the working directory is inside the timeline, a later `rm x.md` / `> x.md` carries no `2_using_timeline/` text to match.
- **`rsync --delete`, and indirection** — destruction performed inside a script (`bash script.sh`) or an editor; the hook only sees `bash script.sh`.

The hook stops casual, naive destruction and makes **filed** notes durably agent-immutable through every ordinary vector. It does **not** provide true immutability. For that, enforce it *below* the agent: OS-level read-only permissions or the immutable bit (`chattr +i`), `git` history on the vault, or filesystem snapshots (ZFS/btrfs/Time Machine).

---

## Setup

**Hook script:** [1_agentic_config/scripts/timeline-guard.sh](../scripts/timeline-guard.sh)

The canonical hook is the **script file linked above** — this doc deliberately does **not** re-embed it, to prevent drift (a pasted copy here already went stale once). Its behavior, by tool (STAGED = top-level; FILED = `YYYY/MM/…`):

- **`Bash`** — blocks deletion (`rm`/`rmdir`/`unlink`/`shred`, `find … -delete`, `git clean`) in **either** zone; blocks `mv`/`cp` that moves a file **out** of the timeline (one timeline path in the command); allows moves **within** it. For a **FILED** path it additionally blocks every write vector (redirect, `sed -i`, `tee`, `truncate`, `dd`, `chmod`, `cp`-into, interpreters) and any `mv` other than the incoming seal. **STAGED** paths get every write vector allowed.
- **`Write`** — blocks a **FILED** path; allows a **STAGED** path (the localizer/staging work zone).
- **`Edit`** — blocks a **FILED** path; allows a **STAGED** path. This **replaces the old four-field content-diff carve-out**: because a note being stamped is still staged (pre-seal), the guard permits the edit on *location* alone — no line-by-line diffing. The discipline of touching only `purpose:`/`projects:`/`repeat:`/`priority:` at stamp time is now a **procedure** rule ([[spec.file-ingestion]] step 9), not a guard check. (Stamping uses a direct `Edit` because typed frontmatter — the `projects:` list and `priority:` integer — must land as literal YAML; the guard no longer inspects *which* fields change.)

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
