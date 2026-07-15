Write a handoff for the current session so a fresh session can resume cleanly. Do this at a clean stopping point — a completed unit of work — not mid-task with things half-broken.

Handoffs live in the gitignored `_handoff/` directory. If it doesn't exist yet, create it: `mkdir -p _handoff`. There are two kinds, and this command may write either or both:

- **The current map** — `_handoff/00_current-map.md`: the durable, "read this first" snapshot of overall project state. **Overwrite it in place** — it is a current-state snapshot, not a log.
- **A session bridge** — `_handoff/<stamp>.md`, where `<stamp>` is the output of `date +%Y-%m-%d_%H-%M` (e.g. `_handoff/2026-07-15_14-55.md`): a point-in-time record of *this* session. **Never overwrite an existing bridge** — each gets a fresh timestamp.

Steps:

1. **Ask which to write:** (a) refresh the current map, (b) also drop a timestamped session bridge, or (c) both. Default to (a) if the user has no preference.
2. **Ask about prior bridges:** list what's already in `_handoff/` (newest first), and ask whether any should be referenced or carried forward into this handoff.
3. **Capture — high-signal, a briefing not a transcript:**
   - **Done** — what was completed, with *concrete* results: commit hashes, file paths, verified state.
   - **Next** — the ordered to-do, with enough context to act on each.
   - **Key decisions & their *why*** — so the next session doesn't re-litigate settled choices.
   - **Gotchas / landmines** — the stale clone, the fetch-only remote, the thing that bit us.
   - **Pointers** — paths, repo URLs, the relevant specs/runbooks. **Point, don't re-explain.**
4. **Keep it lossy by design.** Link to durable docs rather than copying their content in — same principle as the wiki's summaries (see `1_agentic_config/admin/mission.rescue-the-curator.md`).
5. Report what you wrote (which files, which paths).

---

**Why this is a command, not just guidance:** the operational workflow (where handoffs live, the filename format, overwrite-vs-append) is pinned *here*, in one executable place, instead of narrated in a doc we hope reflects our intent. Start a session with the companion `/resume`. Conceptual background — *why* handoffs beat lossy auto-compaction — lives in `1_agentic_config/admin/guide.handoff-management.md`.
