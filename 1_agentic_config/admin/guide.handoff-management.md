---
title: Handoff Management
description: A user primer on handoff files — how to preserve working context across compaction, session end, and directory switches, instead of relying on lossy auto-compaction.
---

# Handoff Management — Optimizing Memory Recovery Across Compaction & Sessions

> **TL;DR** — A *handoff file* is a short, durable, hand-curated snapshot of "where we are" that you write at a clean stopping point. When a session compacts, ends, or you move to a new directory, you recover full working context by having the new session **read the handoff first** — instead of trusting a lossy automatic summary to have kept what matters.

> **⚙ NOW AUTOMATED AS COMMANDS.** The operational workflow is the **`/resume`** command (load context at the start of a session) and the **`/handoff`** command (write it before you stop) — see `.claude/commands/`. Handoffs live in the gitignored `_dev/` directory as `_handoff.current-map.md` (the durable "read first" map) plus timestamped `_handoff.YYYY-MM-DD_HH-MM.md` session bridges. **This document is kept only as background on _why_ handoffs matter; the authoritative _how_ now lives in those two command files.** Where the prompts and paths below still describe the older parent-directory (`../handoff.…`) convention, treat them as superseded by the commands.

---

## Copy-paste prompts (grab & go)

### My personal TL;DR (using latest rounds):

```
Use today's date and time to name a [HANDOFF_FILE] at `../handoff.YYYY-MM-DD-HH-MM-SS.md` 
```

```
Create or overwrite this [HANDOFF_FILE] so a fresh session can pick up cleanly. 
Capture: what we completed this session (with concrete results — commit hashes, 
file paths, verified state), the ordered NEXT steps, as well as key findings, 
including mistakes, and any resulting key decisions made and *WHY*.
Be ESPECIALLY sure to capture any gotchas/landmines. 
Keep it high-signal; point to durable docs rather than re-explaining them. 
Overwrite in place — it's a current-state snapshot, not a log. 
```

```
Read the latest [HANDOFF_FILE] we just saved.
This is my handoff file with the current state of our work. 
Load it fully, then give me a short status report; 
Then bullet points for what's DONE, what's NEXT, 
and ESPECIALLY any GOTCHA issues I should know before we start. 
Don't begin new work until I confirm.
```


---

Two prompts cover almost everything. Substitute the one placeholder, paste, done.

**Substitute:** `<HANDOFF_PATH>` → the absolute path to your handoff file
(e.g. `…/kbs.agent-automated.wikis/DEV-HANDOFF.<project>.md`).

**▶ START of a session — resume from the handoff** (paste as your first message, especially in a new session or a new directory):

```text
Read `<HANDOFF_PATH>` — my handoff file with the current state of this work. Load it
fully, then give me a 3-line status: then bullet points for what's DONE, what's NEXT, 
and any GOTCHA issues I should know before we start. Don't begin new work until I confirm.
```

**⏹ END of a session — refresh the handoff** (paste before you stop, exit, or let it compact):

```text
Create or overwrite my handoff file at `<HANDOFF_PATH>` so a fresh session can pick up
cleanly. Capture: what we completed this session (with concrete results — commit
hashes, file paths, verified state), the ordered NEXT steps, key decisions and *why*,
and any gotchas/landmines. Keep it high-signal; point to durable docs rather than
re-explaining them. Overwrite in place — it's a current-state snapshot, not a log.
```

*(First time? The END prompt doubles as "create" — it makes the file if it doesn't exist yet. If you don't have a path picked, ask: "suggest a stable handoff path outside my repos.")*

---

This is the vault's own philosophy ([[mission.rescue-the-curator]]) turned on the assistant itself: **the summary is lossy by design; keep the durable original and re-load it deliberately.**

---

## The problem: three ways working context gets lost

1. **In-session compaction.** When the conversation fills the context window, the harness *auto-summarizes* older turns to make room. Summarization always discards detail — and it can't know which detail you'll need next. You keep working, but on a thinner record.
2. **Session end → new session.** Claude Code's file memory lives at `~/.claude/projects/<working-dir-slug>/memory/`. A new session in the **same** directory can reload it — but only what was saved there, not the full transcript.
3. **New directory (clone / fork).** The memory path is keyed to the **working directory**. Start a session in a *different* folder (e.g. a fresh clone) and Claude computes a new slug and starts with **empty memory**. Nothing follows you automatically.

A handoff file addresses all three, because it's a plain artifact **you** control — not tied to the context window or to any one directory.

---

## Handoff vs. the alternatives

| Mechanism | What it is | Strength | Weakness |
|---|---|---|---|
| **Auto-compaction** | Harness summarizes older turns when context fills | Automatic; keeps you going | Lossy; you don't choose what's kept; quality varies |
| **Claude file memory** (`~/.claude/…/memory/`) | Per-project saved facts + `MEMORY.md` index | Reloads next session | **Per-directory**; won't cross into a clone/fork |
| **Handoff file** (this guide) | A markdown snapshot at a stable path you choose | Durable, curated, directory-independent | Manual — you must write & keep it current |

They're complementary: memory for durable per-project facts, handoff for the **live "state of the work"** you want to carry anywhere.

---

## What a good handoff contains

Keep it short and high-signal — a briefing, not a transcript:

- **Done** — what was just completed (with the concrete result: commit hash, file path, verified state).
- **Not done / next steps** — the ordered to-do, with enough context to act.
- **Key decisions & their *why*** — so the next session doesn't re-litigate settled choices.
- **Gotchas / landmines** — the stale clone, the fetch-only remote, the thing that bit you.
- **Pointers** — paths, repo URLs, the relevant specs/runbooks.

**Overwrite, don't append forever.** A handoff is a *current-state* snapshot; let it churn. (Contrast the append-only agent log, which is history.)

---

## Where to put it

Put the handoff at a **stable, known path** — and, when you're about to switch directories, **outside** the repos you're moving between, so it survives the jump and isn't accidentally shipped. A parent folder of your projects is ideal, e.g.:

```
…/kbs.agent-automated.wikis/DEV-HANDOFF.<project>.md
```

Then, whatever directory you launch the next session in, your **first message** is simply:

> read `…/DEV-HANDOFF.<project>.md`

and the fresh session is caught up in one step — no reliance on per-directory memory.

---

## Workflow & best practices

- **Write at clean stopping points**, like the end of a completed unit of work — not mid-task with things half-broken.
- **Prefer a fresh session + handoff over a long, heavily-compacted one.** A clean restart primed by a crisp handoff usually beats grinding on a degraded, over-compacted context. (If you *are* compacting, dump a handoff **before** it triggers, while the detail is still live.)
- **In the new session, load the handoff first**, before asking for new work — it's the just-in-time context load, same spirit as [[spec.query-JIT-guidance]].
- **Keep the durable operational detail in real docs**, and let the handoff *point* to them (e.g. [[RUNBOOK.git-ops]], [[setup.claude-code-UX]]) rather than re-explaining them.
- **Ask the assistant to update the handoff** as the last step of a session — "refresh the handoff before we stop."

---

## Quick checklist

- [ ] Handoff lives at a **stable path**, outside repos you switch between.
- [ ] Covers **done / next / decisions / gotchas / pointers**.
- [ ] **Current** — rewritten this session, not stale.
- [ ] New session opens with **"read `<handoff>`"**.
- [ ] Durable details live in linked docs; the handoff just points.

---

**See also:** [[mission.rescue-the-curator]] (the lossy-summary-vs-durable-original principle) · [[setup.claude-code-UX]] (the surrounding Claude Code working environment) · [[spec.query-JIT-guidance]] (loading context just-in-time).
