---
title: OMD Conventions
created: 2026-06-29
updated: 2026-06-29
description: The OMD authoring layer — file/wikilink naming conventions (slug, tl_, project_, slug-pipe, link-by-role) and the page-frontmatter schema, plus tag discipline. The lexical/authoring companion to spec.directory-structure (physical view) and spec.obsidian-as-a-knowledge-graph (logical/graph view).
---

These specifics details are based upon the general specifications in:
* [[spec.directory-structure]]
* [[spec.obsidian-as-a-knowledge-graph]]

If any details below are unclear, resolve their purpose against the two spec files above.

---

## Wikilink Conventions

**Two filename namespaces.** Files live under two regimes:
- **`3_generates_wiki/`** — agent-authored pages use **slugified** filenames: lowercase, hyphen-separated, no special characters (e.g. `large-language-models.md`). Obsidian resolves `[[wikilinks]]` by **filename only** (case-insensitive); it does **not** convert spaces to hyphens, and — verified against Obsidian's link graph on 2026-06-19 — **`aliases:` do NOT resolve wikilinks** (they only help the Quick Switcher and search). So `[[Agent Architectures]]` produces a phantom node even with a matching alias. **Always link to a generated page by its slug, using slug-pipe for a readable label: `[[agent-architectures|Agent Architectures]]`** (or bare `[[agent-architectures]]`). The only display-name links that resolve on their own are single-token names that differ from their slug merely by case (e.g. `[[OpenBrain]]` → `openbrain.md`). **Source pages additionally take a reserved `tl_` prefix** (`tl_<slug>`) so their basename can never collide with the timeline note they mirror; link them as `[[tl_<slug>|Display]]`.
- **`2_using_timeline/`** — source artifacts keep their **original names** (only truly-breaking characters are sanitized; see [[spec.file-ingestion]] step 3). Link to them by **exact name** — parentheses, spaces, `&`, `--` and all resolve directly as an exact filename match (e.g. `[[AI 2027 (Ending 1 of 2 -- Slowdown & Survival)]]`). No slug-pipe needed for timeline files.

**Link form by role:**
- **Notes** (wiki pages, source originals, specs, daily notes — anything read/navigated): plain wikilink, no extension — `[[name]]`.
- **File artifacts** (consumed as files, housed in `2_using_timeline/YYYY/MM/assets/` — skill files, configs, prompt/benchmark files, images): wikilink **with the true extension** — `[[foo.SKILL.md]]`, `[[diagram.png]]`, `[[paper.pdf]]`, `[[config.yaml]]`. The extension is what signals "this is a file artifact." (Requires Obsidian's "Detect all file extensions" setting — see [[checklist.obsidian.setup|checklist.obsidian.setup.md]].)

**Other rules:**
- Every page must have at least one inbound link from another page. No orphans.
- When you create a new page, update at least one existing page to link to it.
- Never put cross-references only in a "See also" footer — weave them into the text.
- **All multi-word / non-case display names on `3_generates_wiki/` pages** use slug-pipe at every call site — `[[deployment-vps|Deployment (VPS)]]`, `[[daniel-kokotajlo|Daniel Kokotajlo]]`. This is the single rule for generated-page links (parenthesized names are just one case of it). Timeline files are the exception: they keep exact-match original names and need no slug-pipe.

---

## Frontmatter

Every note carries YAML frontmatter, but which fields it holds depends on the note's class — and they accrue in **pipeline order**: a collected artifact arrives with its own frontmatter, the agent stamps intent onto it at ingestion (making it a CTN), then the agent authors the GWNs generated from that CTN.

### 1. Collected artifacts — incoming; *used* by the agent, never *authored* by it

What the collection tool wrote; the agent **reads** these and **never alters them**. Web clips (Obsidian Web Clipper) are the rich case:
- `title:` — the original display name (from the web page or browser tab)
- `source:` — the **full web URL** it was clipped from

Other collected artifacts carry less: daily notes and PDFs arrive with their own minimal frontmatter, or none. All of them still become CTNs via §2.

### 2. CTNs — the agent's additions at ingestion

What turns a collected artifact into a Collected Timeline Note: during ingestion the agent **additively stamps** the curator's intent fields onto it, never touching §1's fields (see [[spec.file-ingestion]] steps 8–9):
- `purpose:` — the curator's stated reason for collecting it
- `projects:` — `[[project_<slug>|Display]]` links to the projects it serves
- `repeat:` — spaced-repetition schedule (only if set)
- `priority:` — integer, default `0`

### 3. Every GWN — the agent-authored core

The shared frontmatter of every Generated Wiki Note:

```yaml
---
title: Page Title          # display name (source GWNs: the CTN's clipped name verbatim — parens & all — though the filename is slugified)
aliases: ["Page Title"]    # OPTIONAL: aids Quick Switcher / search only — aliases do NOT resolve [[wikilinks]]. Link via slug-pipe: [[page-title|Page Title]]
type: source | concept | entity | synthesis
tags: [tag1, tag2]         # status / workflow only — see Tag discipline below
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### 4. Source GWNs — add `ctn:`

A source GWN summarizes exactly one CTN, so it adds a single field and **never carries the `sources:` property**:
- `ctn: "[[Original CTN Filename]]"` — an exact-match wikilink to the CTN by its **original name** 
  (no path, no extension; e.g. `[[AI 2027 (Ending 1 of 2 -- Slowdown & Survival)]]`), **never** a web URL.

**How a source GWN mirrors its collected artifact's provenance:**
- **`title:`** carries the original clipped display name verbatim, even though the filename is the bash-safe slug.
- **`ctn:`** points at the CTN — timeline files keep their original names (see Wikilink Conventions), so the link resolves by exact match and stays relocatable. The CTN's dated folder (`2_using_timeline/<YYYY>/<MM>/`) is recoverable from the source GWN's `created:` date.
- The original web URL is **not** copied up; it stays in the CTN's `source:` and is reached by progressive disclosure: source GWN → (`ctn:` wikilink) → CTN → its `source:` URL — the path the Query fallback follows to the lossless original.

### 5. Non-source GWNs — add `sources:`

Concept / entity / synthesis GWNs synthesize *from* multiple sources, so they add a list and **never carry the `ctn:` property**:
- `sources: [source-slug-1, source-slug-2]` — slugs of the source GWNs this page draws on.

### Tag discipline

Tags mark **status and workflow state only** — not topic or category membership. Examples: `stub`, `needs-review`, `outdated`, `contradicted`, `to-expand`. Topic relationships between concepts are expressed exclusively through `[[wikilinks]]` woven into prose. 

Never use tags as a substitute for wikilinks.

---

## Source Page Format

A source GWN's **frontmatter** is the §3 + §4 schema above (`type: source`, plus `ctn:`). Its **body** follows this structure:

```markdown
## Summary

[2–4 paragraph summary of the source. Factual, close to the original. Save interpretation for synthesis pages.]

## Key Points

- Point one
- Point two
- Point three

## Key Concepts

Links to concept pages this source introduces or develops: [[Concept A]], [[Concept B]]

## Key Entities

Links to entity pages mentioned: [[Person Name]], [[Organization Name]]

## Connections

- **Corroborates**: [[Other Page]] — brief reason
- **Extends**: [[Other Page]] — brief reason
- **Contradicts**: [[Other Page]] — brief reason (add matching note on that page)

## Quotes

> "Notable direct quote from the source."
```

---

## wiki.index.md Format

```markdown
# Wiki Index
_Last updated: YYYY-MM-DD — N sources, N concepts, N entities, N synthesis pages_

## Sources
- [[slug]] — one-line summary (YYYY-MM-DD)

## Concepts
- [[slug]] — one-line summary

## Entities
- [[slug]] — one-line summary

## Synthesis
- [[slug]] — one-line summary
```

Use **short basename wikilinks** — the section heading conveys the category, so no path is needed. Add a path only to disambiguate a genuine basename collision. Keep entries alphabetical within each section. This is the LLM's navigation entry point for queries — keep it accurate and current.
