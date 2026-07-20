---
title: File Ingestion
created: 2026-06-23
updated: 2026-07-07
description: The ingestion process — how a file dropped in 2_using_timeline/ becomes a filed timeline artifact (stamped with intent metadata — purpose/projects/repeat/priority) plus a generated source page and its wiki cross-references. Includes the ingest interview.
---
You will take timeline pages and build four types of generated wiki pages: source/concept/entity/synthesis   
  
# File Ingestion

**Trigger:** the curator drops a file in `2_using_timeline/` and says **"ingest [filename]."**

**Sources** (all ingested identically): web clips, PDFs, any markdown file, and daily notes (`YYYY-MM-DD.md`). 

## The Timeline is the INBOX

- Files in `2_using_timeline/` are PENDING. They can wait as long as needed.
- Files in `2_using_timeline/YYYY/MM/` are PROCESSED.
- A **`_FIX-…`** prefix marks files in `2_using_timeline/` for curator attention (they sort to the top):
  - **`_FIX-DUPE_<name>`** — duplicate of an already-ingested file (step 4); a working scrap — mine anything useful into a daily note, then discard.
  - **`_FIX-NAME_<name>`** — un-wikilinkable filename, parked during unattended ingest (step 3); rename it (the proposed name is in the log) and it can ingest.
  - **`_FIX-LINK_<name>`** — unresolved imported link(s); ingest aborted for the curator to fix (step 5).
- The agent **never deletes** anything in `2_using_timeline/`, `_FIX-…` files included. The curator removes them from the Obsidian UI.

## There are Two Types of Timeline Notes

- Notes generated using Obsidian's Web Clipper browser extension: 
	- These are intended to be standalone artifacts (saved against inevitable "link rot")
	- Often contain links to images, videos, PDFs, repos, etc.
- Daily Notes (a standard Obsidian feature):
	- Tend to have bookmarks to external URLs the user has saved for future attention
	- May also contain free-form content 
	- We do not have to worry about the timing of WHEN to ingest a daily note:
		- If you open Obsidian the next day and hit the daily note button, you simply get a new note for the new day.
		- Any existing (now "old") daily notes simply remain until explicitly ingested by the user.

## Path Convention — decide the tool path at DESIGN time, not RUN time

Every action goes through one of two paths. **We choose the path here, in the spec, so that at run time there is nothing to deliberate — just execute.** Each step below is tagged with the path it uses.

- **`[direct]` — the default workhorse.** Filesystem tools (`Read`/`Edit`/`Write`/`Bash`). Faster (no round-trip), deterministic, greppable, scriptable, can write **typed** YAML (real lists/integers — see step 9), and works even when Obsidian is closed. **When in doubt, direct.**
- **`[obsidian]` — the `obsidian` CLI, authoritative graph queries only.** Obsidian's live link index via the `obsidian` CLI (`backlinks`, `orphans`, `unresolved`) — used only when a regex over link *text* can't be trusted to judge resolution (mainly `lint`; occasionally one ambiguous ingest link). Requires the desktop app running. This replaced the retired Local REST API / MCP path — see [[HISTORY.explored-and-retired]]. Note there is **no** agent command for link-repointing moves anymore; ingest sidesteps needing one by keeping every filing move **name-preserving** (basename unchanged, so inbound `[[basename]]` links survive a raw `mv`).

One caution the tags encode: typed frontmatter (real YAML lists/integers) must be written as literal YAML by a direct `Edit` — why step 9 is `[direct]` — and editing a file on disk that Obsidian has open can race its cache, so prefer direct edits when Obsidian isn't mid-write on the same file.

## Ingestion Procedure

1. **`[direct]` Preflight.** Ingestion is fully filesystem-based — it needs **no running Obsidian and no MCP.** Nothing here hard-blocks on external tooling; the only external reach is the step-10 attachment localizer (and only if the note carries remote images), which fails loud on its own. *(Authoritative graph queries via the `obsidian` CLI belong to `lint`, not ingest.)*

2. **`[—]` Determine mode of operation** — this sets the default posture for every branch below (pure control decision, no I/O):
   - **Attended** — a curator is present, answering interactively:
	   - Prompt the curator at each decision point and wait for a response.
   - **Unattended** — a batch run, no curator: 
	   - Never block on a prompt; auto-apply the safe default.
	   - **Park** anything that needs a human (`_FIX-NAME_` / `_FIX-DUPE_`), log it, and report at end of batch.

3. **`[direct]` Filename check.** Run `scripts/filename-check.sh "<name>"` (the canonical disallowed-character list). 
   It preserves the human-readable name and returns one of three results:
   - **`clean`** — safe; keep the name.
   - **`recommend-fix`** — legal but not bash-safe (`: * ? " < >`, or a leading `-` / `.`); the script prints a `PROPOSED:` name.
   - **`must-fix`** — breaks wikilinks (`[ ] | # ^ \ /`), uningestible as-is; the script prints a `PROPOSED:` name.

   **Then handle per mode:**
   - **Attended** (this is **Q0** — runs even if Q1–Q5 are skipped): 
	   - on `recommend-fix`/`must-fix`, show the `PROPOSED:` name and wait for approval or a correction; 
	   - on `clean`, say nothing.
   - **Unattended:** 
	   - `recommend-fix` → auto-apply `PROPOSED:`, log, continue. 
	   - `must-fix` → rename to `_FIX-NAME_<name>`, log, skip.
   - Renames use `mv` **within** `2_using_timeline/` (guard-permitted). The timeline file keeps its human-readable name; the source page gets `tl_<slug>`.

4. **`[direct]` Duplicate check.** If `2_using_timeline/YYYY/MM/<name>` already exists, **stop** — already ingested. 
   Offer to rename the new copy `_FIX-DUPE_<name>` (auto-apply in unattended mode).

5. **`[direct]` Imported-link scan** *(foreign-vault markdown imports only — a no-op for web clips and PDFs).* *(Escalate to `[obsidian]` `obsidian backlinks` only if a link's resolution is genuinely ambiguous — e.g. YAML-wrapped — where a regex can misjudge.)*
   - **Why.** A note authored in another Obsidian vault carries `[[wikilinks]]` that resolved there but **dangle here**, creating phantom nodes.
   - **Scan** every `[[wikilink]]` the source carries — **body *and* frontmatter** (property links hide in the Properties panel, not the prose).
   - **Inert links don't count.** A body link inside a code span (`` `[[x]]` ``) is not parsed by Obsidian and creates no node — skip it. This is the curator's legitimate way to neutralize a body link.
   - **Backticks don't neutralize in frontmatter.** YAML isn't markdown, so backticks are literal and the link stays live — to clear a property link the curator must remove the brackets or delete the value.
   - **The gate:** any unresolved, non-inert link **aborts the ingest** — the agent stops processing this timeline note; nothing downstream runs.
   
   **Then handle per mode:**
   - **Attended** — print each offending link verbatim (easy to copy → open the note → search → fix), noting *where* it sits (body / which property); for a **renamed sibling** (a file renamed earlier in this ingest), give the corrected name. Then prompt the curator to fix the note in place and re-issue `ingest`, which then passes the scan.
   - **Unattended** — park the file as `_FIX-LINK_<name>`, log the offending links, and skip to the next.

6. **`[direct]` Read & summarize.** Read the source and present a **3–5 bullet summary**, 
   then ask: *"Good summary, or should I take another pass?"* Revise until the curator approves.

7. **`[—]` Ingest interview.** Conduct the interview (Q1–Q5, defined below) — unless the curator says **"skip."** Its answers feed steps 8–9.

8. **`[direct]` Write the wiki** (one pass, no prompting). Write the **source page** (summary, key points, connections — *not* `purpose`/`projects`; those now live on the timeline note); create/update **concept** and **entity** pages; create any **`project_<slug>`** page named in Q3 that doesn't yet exist — **a project page IS an entity GWN**: file it in `3_generates_wiki/entities/` with `type: entity`; the `project_` prefix is only a naming convention, **not a fifth GWN type**; weave cross-references; update `wiki.index.md` and the current month's log.

9. **`[direct]` Stamp the timeline note.** In a **single direct Edit** to the timeline note's frontmatter, write the four ingest fields:
   - **`purpose:`** — the approved Q1 sentence.
   - **`projects:`** — a YAML **list** of `[[project_<slug>|Display]]` links (Q3).
   - **`repeat:`** — only if set in Q4 (otherwise omit).
   - **`priority:`** — a single **integer**, default `0`, always written (Q5).

   Write it with a direct **Edit** so the values land as **literal typed YAML** — a real list for `projects:` and a bare integer for `priority:` (a stringifying property-setter would mangle them into `'["..."]'` and `"1"`, defeating the typed schema). **Anchor the Edit on any existing frontmatter line (e.g. `created:`), leave that line unchanged, and add/replace the four fields around it** — so even a brand-new web clip (which arrives with *none* of the four) is stamped in one pass. The note is still **staged** here (top-level `2_using_timeline/`), so the guard permits the edit on *location* alone — staging is the mutable work zone. **Discipline (procedure, not guard-enforced): stamp only the four ingest fields; the CTN is the curator's lossless original.** The **seal** is step 11: once filed into `YYYY/MM/`, the note becomes agent-immutable — no further edits, ever. (Location model: [[spec.timeline-guard-hook]].)
   - **Verification gate:** every `[[wikilink]]` written this pass — wiki pages *and* the timeline note's `[[project_<slug>]]` links — must resolve. Stub or plain-text any that don't. Do not finish with dangling links.

10. **`[direct]` Localize attachments.** Web clips often embed **remote** images (`![alt](https://…)`) that rot with the source. Localize them headlessly — no Obsidian, no modal (the retired MCP "Download attachments" command is gone; see [[HISTORY.explored-and-retired]]):

    ```bash
    python3 scripts/attachment-localize.py "<staged-note>" "2_using_timeline/attachments/"   # add --dry-run to preview
    ```

    It downloads each remote image embed into the **staged** `2_using_timeline/attachments/` dir (top-level = mutable zone) under a bash-/wikilink-safe, hash-deduped filename and rewrites the embed to a local `![[basename|alt]]` (basename-only, so the later filing move in step 11 can't break it). Staging assets *inside* the timeline keeps the step-11 filing move `staged → filed` internal, which is the only move the guard's seal allows.

    **Verification gate — do NOT skip (this is the silent-failure guard).** The script exits **`0` only when *every* embed localized**; on any fetch error, HTTP error, zero-byte download, or a remote embed left un-rewritten it exits **non-zero and leaves the note UNCHANGED**. Treat non-zero as a hard **stop** — do not proceed to step 11; **never file a note without its images.** A note with no remote embeds is a clean exit-`0` no-op. (Behavior is pinned by `tests/test-localizer.sh`.)

11. **`[direct]` File the artifact (the SEAL).** Move any staged assets (`2_using_timeline/attachments/`) → `2_using_timeline/YYYY/MM/assets/`, then move the article → `2_using_timeline/YYYY/MM/`. Use `mv` **within** the timeline (basename is preserved, so inbound basename links survive). This move is the **seal**: once filed, the note is agent-immutable — the guard blocks every further write to it. So do this **only after** stamping (step 9) and localizing (step 10) are done and verified. *(The move is **name-preserving** — basename unchanged — so inbound `[[basename]]` links survive the raw `mv`; no link-repointing tool is needed, which is why the retired `vault_move` is not missed here.)*

12. **`[direct]` Set provenance.** On the source page, `ctn: "[[Original Filename]]"` — the timeline note's original name, no path/extension, never a URL. Confirm `title:` holds the verbatim original display name.

## Ingest Interview

Five questions, in order; **"none"** is a valid answer to any. (Q0 is the filename check, step 3 — it runs even when Q1–Q5 are skipped.) Q1/Q3/Q4/Q5 are stamped onto the **timeline note** (step 9); Q2 shapes concept placement in the wiki (step 8).

- **Q1 — Purpose.** Distill the answer into a 1–2 sentence statement, offer it back for approval, and record the approved version in `purpose:` (not the raw answer).
- **Q2 — Categories.** Propose the categories you see, mapped to existing concept pages. Run the **conflation check**: if a category overlaps an existing cluster, surface it and let the curator choose — new hub / fold into existing / genuinely distinct. Never silently create a near-duplicate cluster. Create a concept hub only when the category is genuinely new.
- **Q3 — Projects.** Each named project must have a **`project_<slug>`** page — **an entity-type GWN filed in `3_generates_wiki/entities/` with `type: entity`** (a project is a legal/organizational entity in the graph; the `project_` prefix is a naming convention, **not** a separate GWN type) — created this pass if missing; record it in `projects:` as a `[[project_<slug>|Display]]` link. (Collaboration-area projects in `4_collaboration/` may reference back to these entity pages; the GWN node itself is always an entity.)
- **Q4 — Repeat.** A spaced-repetition schedule for the timeline note (consumed by the Repeat plugin — a separate, optional install). Ask **"Repeat? (y / n / specify)."** On yes, offer presets (`every 1 week`, `every 1 month`) or take a free-form interval (`every 6 weeks`, `spaced every 3 days`); normalize to the plugin's syntax, lowercased. On no, **omit `repeat:` entirely.** Recorded in `repeat:` (step 9); `due_at:` is then plugin-managed.
- **Q5 — Priority.** A single integer for later (DataView-based) sorting — positive, negative, or zero; an integer scale leaves unlimited room to slot an item between any two others. Ask **"Priority? (integer, default 0)."** **Defaults to `0` and is always recorded** (even on skip), so every note is sortable. Sort *semantics* (e.g. whether higher = more urgent) are deferred to when we build the sort. Recorded in `priority:` (step 9).
