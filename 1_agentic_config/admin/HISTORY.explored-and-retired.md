# Development History — Explored & Retired

_Why the current design looks the way it does. This doc records major approaches we **tried and abandoned** (or fundamentally changed), with the reasoning, so a future reader never mistakes a deliberate choice for naïveté. It complements the ADRs: an **ADR** records *what we decided*; this **HISTORY** records *what we explored and why we left it*._

Newest entries on top. Each entry: what we tried → why we left it → what replaced it.

---

## 2026-Q3 — Obsidian Local REST API / MCP, for attachment automation → RETIRED

**What we tried.** The "Local REST API with MCP" plugin (`obsidian-local-rest-api` v4.1.3) exposes an MCP server that lets the agent drive Obsidian internals — set the active file, trigger Obsidian commands, read the link graph. Our ingest pipeline depended on it for one critical operation: pulling a web clip's **remote images into the vault** via the core command **"Download attachments for current file"** (`editor:download-attachments`), so Collected Timeline Notes become durable, self-contained originals (no link rot).

**Why we left it.** That command **cannot be run non-interactively through any Obsidian interface** — it opens a GUI confirmation modal (a thumbnail picker + Download/Cancel) that waits on a human click. Triggering it headlessly (via `command_execute`) returns `OK` but only *dispatches* the command; the modal then hangs, and nothing downloads. This makes both unattended *and* practical attended ingest untenable ("we're not going to hang around clicking a modal every time").

**We verified this is structural, not an oversight** (2026-07-05, against the plugin's own source):
- Command execution is `executeCommandById(commandId)` — **parameter-less**. The plugin's OpenAPI `POST /commands/{id}/` takes only the command id; there is no request body, no options, no attachment endpoint.
- The limitation is **Obsidian's command API itself**: `Command` callbacks receive **zero arguments**, so *nothing* that triggers a command — REST, MCP, or the official `obsidian` CLI — can tell it to skip a modal it chooses to open. The modal lives inside the command's own callback, out of every caller's reach.
- This is a **design boundary, not a bug.** Obsidian commands are deliberately parameter-less UI actions (the command-palette model), and "Download attachments" was built as an **interactive convenience** (you review which attachments to pull) — never as an automation primitive. Obsidian *does* ship real headless automation where it makes sense (the `obsidian` CLI exposes `backlinks`/`unresolved`/`orphans` as first-class commands) — they simply, and correctly, didn't make an inherently-interactive command headless.

> **So if you're reading the `curl`-based attachment localizer and thinking "why didn't they just use the API?" — we did. The API can only *trigger* a parameter-less command; the one we needed is interactive-by-design and unreachable headlessly. Fetching the images ourselves is the *intended* path for automation.**

**What replaced it.**
- **Attachments** → a direct fetch localizer (parse `![alt](url)` → download → rewrite to `![[local|alt]]`), which is headless, deterministic, needs no Obsidian running, and produces bash-safe filenames (the native command left literal `*` in names).
- **Graph/link queries** (danglers, orphans, backlinks — the one genuinely valuable thing MCP did) → the **official `obsidian` CLI** (`unresolved`/`orphans`/`backlinks`), a robust terminal tool rather than a self-signed-HTTPS server.
- **Everything else** → direct filesystem ops.
- Net: the entire fragile MCP surface (self-signed TLS that Claude Code's native client rejects, per-vault ports, "Obsidian must be running," stale connection status, the modal) is removed. See [[ADR.mcp-removal-and-timeline-immutability|the ADR]] for the full replacement architecture.

**Related fragility we won't miss** (all encountered during the MCP period, 2026-Q2→Q3): a TLS regression where Claude Code's native binary began rejecting the plugin's self-signed cert (masked for weeks because `curl -k` skips the exact check Claude enforces); mandatory unique `insecurePort` per vault; and MCP tools loading only at session start.

---

## 2026-Q3 — Content-based timeline guard (field carve-outs) → REPLACED by location-based immutability

**What we tried.** The `timeline-guard.sh` hook protected `2_using_timeline/` by **inspecting the content of each edit** — allowing a write only when every *changed line* was one of the four intent fields (`purpose:`/`projects:`/`repeat:`/`priority:`). Adding headless attachment localization would have needed a *second* content carve-out (image-link rewrites), and every carve-out widens the trusted surface and the risk a subtle guard bug lets a bad edit through ("holes in the picket fence").

**Why we left it.** Content-diffing is the wrong axis. The moment we went direct-filesystem (post-MCP), the agent needed to write CTN bodies during ingest, and negotiating that through content carve-outs got complex and fragile.

**What replaced it.** **Location-based immutability**: a CTN is a **staged CTN** (top-level `2_using_timeline/*`, freely agent-editable — stamp + localize happen here) until the one-way **filing** move into `2_using_timeline/YYYY/MM/[assets/]` **seals** it into a **filed CTN**, which is **agent-immutable**. The guard becomes a simple path check (no content diffing); the frontmatter *and* image-localization carve-outs both disappear. Deletion stays curator-only everywhere. (Spaced-review `due_at:` churn on filed CTNs is the Repeat plugin writing via Obsidian internals — orthogonal to the agent, so the guard neither sees nor blocks it; "agent-immutable" is the precise claim.) See [[ADR.mcp-removal-and-timeline-immutability|the ADR]].

---

_Add new entries above this line as approaches are retired or fundamentally changed._
