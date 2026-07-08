---
title: "ADR: MCP Removal & Location-Based Timeline Immutability"
created: 2026-07-07
updated: 2026-07-07
status: Accepted — implemented & test-validated 2026-07-07
description: Architecture Decision Record. Retire the Obsidian Local REST API / MCP server entirely (attachments → a headless localizer, graph queries → the obsidian CLI, everything else → direct filesystem) and replace content-based timeline-guard carve-outs with location-based immutability (staged CTN → filing seal → filed CTN, agent-immutable). Records what we DECIDED; the exploration narrative lives in HISTORY.explored-and-retired.
---

# ADR: Retire the Obsidian MCP server; adopt location-based timeline immutability

**Status:** Accepted — implemented and test-validated 2026-07-07 (harness suite 74/74).
**Deciders:** the curator and the wiki agent (dogfooded on this host).
**Complements:** [[HISTORY.explored-and-retired]] records *what we explored and why we left it*; this ADR records *what we decided and the resulting architecture*. Implementation lives in [[spec.file-ingestion]], [[spec.timeline-guard-hook]], [[spec.lint-health-check]], and [[setup.obsidian-tooling]].

---

## Context

Two independent pressures converged in 2026-Q3:

1. **The MCP dependency had one load-bearing job it could not do.** Ingest relied on the Obsidian Local REST API / MCP server (`obsidian-local-rest-api`) for **"Download attachments for current file"** — pulling a web clip's remote images into the vault so a Collected Timeline Note (CTN) becomes a durable, self-contained original. That command is **interactive-by-design**: it opens a GUI modal and waits on a human click. It is unreachable headlessly — not a bug but a structural boundary of Obsidian's parameter-less command API (verified against plugin source, 2026-07-05). Full analysis: [[HISTORY.explored-and-retired]].
2. **The MCP surface was fragile for everything else too** — self-signed TLS that Claude Code's native client rejects (masked for weeks because `curl -k` skips the very check Claude enforces), a mandatory unique port per vault, "Obsidian must be running," stale connection status, and tools that load only at session start.

Separately, the **timeline guard** enforced immutability by **content-diffing** each edit — permitting a write only when every changed line was one of four intent fields. Going direct-filesystem (post-MCP) means the agent must write CTN *bodies* during ingest (to localize images); bolting a second content carve-out onto the guard would widen the trusted surface and multiply the ways a subtle guard bug lets a bad edit through.

---

## Decision

1. **Retire the Obsidian MCP server entirely.** Remove it as an ingest/lint dependency; uninstall the plugin at cutover.
2. **Attachments → a headless localizer.** `1_agentic_config/scripts/attachment-localize.py` parses `![alt](url)`, downloads into `2_using_timeline/attachments/` under bash-/wikilink-safe deduped names, and rewrites to `![[local|alt]]`. It **fails loud, never silent** — any fetch/HTTP error, zero-byte download, or un-rewritten embed exits non-zero and leaves the note unchanged.
3. **Authoritative graph queries → the official `obsidian` CLI** (`unresolved` / `orphans` / `backlinks`) — the one genuinely valuable thing MCP did, now via a robust terminal tool.
4. **Everything else → direct filesystem** (`Read`/`Edit`/`Write`/`Bash`).
5. **Timeline immutability moves from content-based to LOCATION-based.** A CTN is a **staged CTN** (top-level `2_using_timeline/*`, freely agent-editable — stamp + localize happen here) until the one-way **filing** move into `2_using_timeline/YYYY/MM/[assets/]` **seals** it into a **filed CTN** (agent-immutable). Deletion is **curator-only in both zones**. Pipeline: `stage → stamp + localize → file (seal) → generate`.
6. **Rewrite `timeline-guard.sh` to pure path predicates.** No content diffing. Both the four-field frontmatter carve-out *and* the would-be image-localization carve-out disappear; the guard becomes: staged = writable, filed = read-only, delete = curator-only, and the sole filed-touching write allowed is the staged→filed seal move.

---

## Consequences

**Positive**
- **The entire fragile MCP surface is gone** — no self-signed TLS, no per-vault ports, no "app must be running" for ingest, no stale status, no modal.
- **Ingest is headless and deterministic** — the localizer needs no running Obsidian and produces safe filenames the native command didn't.
- **The guard is radically simpler** — a location check, not a content diff. Fewer moving parts, a smaller trusted surface, and it now closes write vectors the verb-only guard leaked (a bare `> filed.md`, `sed -i`, `truncate`, interpreters).
- **Everything is pinned by local tests** — `test-localizer.sh` (13/13) and `test-guard.sh` (36/36); full suite 74/74, no GitHub/Obsidian needed.

**Negative / tradeoffs (accepted)**
- **The staged zone is intentionally wide open.** A staged CTN is protected only *after* it's filed; protecting the curator's original depends on filing promptly. (The seal, not the staging zone, is the lock.)
- **Reads of a *filed* note via a shell interpreter are conservatively blocked** (to guarantee no `python open(w)` write slips through) — the agent reads filed notes with the Read tool instead.
- **No agent command for link-repointing moves** anymore (`vault_move` is gone). Mitigated by making every filing move **name-preserving**, so inbound `[[basename]]` links survive a raw `mv`; a genuine rename-with-repoint is a manual/Obsidian-UI task.
- **The `obsidian` CLI still needs the desktop app running**, and on Flatpak/Snap a one-time socket-bridge (see [[setup.obsidian-tooling]]). But this affects only `lint`'s authoritative queries — ingest/query/admin all work without it.

**Neutral / operational**
- The Repeat plugin's `due_at:` churn on filed CTNs is Obsidian writing via its own internals — orthogonal to the agent, so the guard neither sees nor blocks it. "Filed CTNs are **agent**-immutable" is the precise claim.

---

## Implementation & validation (2026-07-07)

- **Scripts:** `attachment-localize.py` (new), `timeline-guard.sh` (rewritten to location predicates).
- **Tests:** `tests/test-localizer.sh` (13/13), `tests/test-guard.sh` (36/36), wired into `tests/run-all.sh` → **74/74**.
- **Specs/docs updated:** [[spec.file-ingestion]] (path convention + steps 1/5/9/10/11), [[spec.timeline-guard-hook]], [[spec.lint-health-check]], `spec.testing`, [[setup.obsidian-tooling]], [[HISTORY.explored-and-retired]], the deploy checklists, and `README`.

**Still open at time of writing** (tracked in the working handoff): push the batch to the framework repo. *(Updated 2026-07-07: `lint` now invokes the `obsidian` CLI, and the **full MCP cutover is DONE** — the `obsidian-local-rest-api` plugin dir, its `community-plugins.json` entry, the `claude mcp` registration, the `next-obsidian-port.sh` helper, and the on-disk API key were all removed. The framework no longer ships or enables any MCP surface.)*
