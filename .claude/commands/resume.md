Resume this project from its handoff. Load prior context **before** doing any new work — do not start new work until the user confirms.

Steps:

1. **Read the current map** — `_dev/_handoff.current-map.md` — in full. It is the durable "read this first" project state.
   - If `_dev/` or that file doesn't exist yet: during the transition also check the parent directory (`../`) for a legacy `DEV-HANDOFF.*.md`, and read that instead. If nothing is found anywhere, say so plainly and offer to start one with `/handoff` — then stop.
2. **Survey the session bridges** — list the timestamped `_dev/_handoff.<YYYY-MM-DD_HH-MM>.md` files, newest first. Offer to read the latest (or a specific one) for point-in-time detail. Read one if the user asks, or if the current map looks stale relative to the newest bridge.
3. **Give a status report:**
   - A 3-line status up top.
   - Then **Done** / **Next** / **Gotchas** as bullet lists — lead with the gotchas that would bite immediately.
4. **Stop and wait for confirmation** before beginning any new work.

This pairs with — it does not replace — the session-startup checks in `AGENTS.md` (symlink integrity, Obsidian CLI health, log restore). Run those too if starting cold.

---

**Why this is a command:** it makes "load the durable context first" a single keystroke and a deterministic procedure, rather than something we remember to do. Write the counterpart with `/handoff` at the end of a session. Background on the approach: `1_agentic_config/admin/guide.handoff-management.md`.
