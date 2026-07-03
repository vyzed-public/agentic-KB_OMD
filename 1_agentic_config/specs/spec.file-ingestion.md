---
title: File Ingestion
created: 2026-06-23
updated: 2026-06-23
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

- **`[direct]` — the default workhorse.** Filesystem tools (`Read`/`Edit`/`Write`/`Bash`). Faster (no round-trip), deterministic, greppable, scriptable, can write **typed** YAML the property API can't (real lists/integers — see step 9), and works even when Obsidian is closed. **When in doubt, direct.**
- **`[MCP]` — Obsidian-internal only.** The Obsidian Local REST API. Reserved for operations with **no filesystem equivalent**: (a) triggering Obsidian commands (e.g. attachment download), (b) authoritative backlink/graph resolution (Obsidian's live link index, not a regex guess), and (c) moves/renames that must **auto-repoint inbound `[[wikilinks]]`** (`vault_move`, which a raw `mv` does not do).

Two cautions the tags encode: the property API **stringifies** typed frontmatter (why step 9 is `[direct]`), and editing a file on disk that Obsidian has open can race its cache — prefer direct edits when Obsidian isn't mid-write on the same file.

## Ingestion Procedure

1. **`[MCP]` MCP check.** If the Obsidian Local REST API MCP server is unreachable, **stop** and notify the curator — nothing downstream can complete without it.

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

5. **`[direct]` Imported-link scan** *(foreign-vault markdown imports only — a no-op for web clips and PDFs).* *(Escalate to `[MCP]` backlink resolution only if a link's resolution is genuinely ambiguous — e.g. YAML-wrapped — where a regex can misjudge.)*
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

8. **`[direct]` Write the wiki** (one pass, no prompting). Write the **source page** (summary, key points, connections — *not* `purpose`/`projects`; those now live on the timeline note); create/update **concept** and **entity** pages; create any **`project_<slug>`** page named in Q3 that doesn't yet exist; weave cross-references; update `wiki.index.md` and the current month's log.

9. **`[direct]` Stamp the timeline note.** In a **single direct Edit** to the timeline note's frontmatter, write the four ingest fields:
   - **`purpose:`** — the approved Q1 sentence.
   - **`projects:`** — a YAML **list** of `[[project_<slug>|Display]]` links (Q3).
   - **`repeat:`** — only if set in Q4 (otherwise omit).
   - **`priority:`** — a single **integer**, default `0`, always written (Q5).

   Use the **Edit tool, not the property API** — `vault_patch` stringifies a list into `'["..."]'` and an integer into `"1"`, defeating the typed schema. **Anchor the Edit on any existing frontmatter line (e.g. `created:`), leave that line unchanged, and add/replace the four fields around it** — so even a brand-new web clip (which arrives with *none* of the four) is stamped in one pass. This is the *only* agent write allowed into a timeline note (the immutability carve-out). The `timeline-guard.sh` hook enforces it: **an Edit is allowed only when every *changed* line is one of the four fields — `purpose:`, `projects:`, `repeat:`, `priority:` (or a `projects:` `  - ` list item); any change to the body, a `---` fence, or another frontmatter field is blocked**, as are deletes, overwrites, and move-outs.
   - **Verification gate:** every `[[wikilink]]` written this pass — wiki pages *and* the timeline note's `[[project_<slug>]]` links — must resolve. Stub or plain-text any that don't. Do not finish with dangling links.

10. **`[MCP]` Download attachments** (set active file → "Download attachments for current file"). Images land in `attachments/`. If it fails, stop — do not move the article without its images.

11. **`[direct]` File the artifact.** Move any `attachments/` (such as images) to `YYYY/MM/assets/`; move the article → `YYYY/MM/`. Use `mv` within the timeline (basename is preserved, so inbound basename links survive). *Exception: `[MCP]` `vault_move` if a move/rename must auto-repoint inbound `[[wikilinks]]` — not the case for a name-preserving file into `YYYY/MM/`.*

12. **`[direct]` Set provenance.** On the source page, `ctn: "[[Original Filename]]"` — the timeline note's original name, no path/extension, never a URL. Confirm `title:` holds the verbatim original display name.

## Ingest Interview

Five questions, in order; **"none"** is a valid answer to any. (Q0 is the filename check, step 3 — it runs even when Q1–Q5 are skipped.) Q1/Q3/Q4/Q5 are stamped onto the **timeline note** (step 9); Q2 shapes concept placement in the wiki (step 8).

- **Q1 — Purpose.** Distill the answer into a 1–2 sentence statement, offer it back for approval, and record the approved version in `purpose:` (not the raw answer).
- **Q2 — Categories.** Propose the categories you see, mapped to existing concept pages. Run the **conflation check**: if a category overlaps an existing cluster, surface it and let the curator choose — new hub / fold into existing / genuinely distinct. Never silently create a near-duplicate cluster. Create a concept hub only when the category is genuinely new.
- **Q3 — Projects.** Each named project must have a **`project_<slug>`** page (create it this pass if missing); record it in `projects:` as a `[[project_<slug>|Display]]` link.
- **Q4 — Repeat.** A spaced-repetition schedule for the timeline note (consumed by the Repeat plugin — a separate, optional install). Ask **"Repeat? (y / n / specify)."** On yes, offer presets (`every 1 week`, `every 1 month`) or take a free-form interval (`every 6 weeks`, `spaced every 3 days`); normalize to the plugin's syntax, lowercased. On no, **omit `repeat:` entirely.** Recorded in `repeat:` (step 9); `due_at:` is then plugin-managed.
- **Q5 — Priority.** A single integer for later (DataView-based) sorting — positive, negative, or zero; an integer scale leaves unlimited room to slot an item between any two others. Ask **"Priority? (integer, default 0)."** **Defaults to `0` and is always recorded** (even on skip), so every note is sortable. Sort *semantics* (e.g. whether higher = more urgent) are deferred to when we build the sort. Recorded in `priority:` (step 9).
