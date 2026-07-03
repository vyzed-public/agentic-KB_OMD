---
title: Lint / Health Check
created: 2026-06-29
updated: 2026-06-29
description: The lint (health-check) operation — the full checklist the agent runs on demand over the wiki graph (dangling wikilinks, frontmatter type-marker conflicts, orphans, contradictions, stale claims, missing pages/cross-refs, cluster coherence) and how to resolve each. AGENTS.md's Lint op is a dovetail pointing here.
---

# Lint / Health Check

**Trigger:** the human says **"lint"** or **"health check."**

Check for and report:
- **Dangling wikilinks (errors, not warnings)** — scan **every note's `[[links]]`, across `3_generates_wiki/` *and* the timeline source notes, in both the body *and* the frontmatter/properties** (`parent(s):`, `related:`, `transcript:`, `ctn:`, …). Frontmatter links are the easiest to miss — they live in the Properties panel, not the prose, and the body backtick trick can't silence them (YAML isn't markdown). A link is dangling if it resolves to no file. Judge resolution by Obsidian's **real** rules (each learned the hard way — verify against the live link graph via the Obsidian MCP `vault_read` backlinks, don't assume):
  - Links resolve by **filename only** — exact basename (case-insensitive) *or* full vault-relative path (`[[3_generates_wiki/concepts/foo]]` resolves). **`aliases:` do NOT resolve `[[wikilinks]]`** — they only feed Quick Switcher/search, so an alias never rescues a display-name link.
  - Links inside **code spans / backticks** (`` `[[x]]` ``) are **inert** — not links; do not flag them.
  - **Fix generated-page** danglers: point at the slug (slug-pipe `[[slug|Display]]`), stub the target, or make it plain text.
  - **Flag (don't fix) timeline source-note** danglers: imported notes carry cross-vault links (see [[spec.file-ingestion]] step 5); the note is the verbatim original and the guard blocks editing it, so report for the curator to fix the name / neutralize / leave.
  Causes phantom node creation in the graph. Distinct from orphans: an orphan *exists* but has no inbound links; a dangling link points at a target that *doesn't exist*.
- **Frontmatter type-marker conflicts** — `ctn:` and `sources:` are mutually exclusive: `ctn:` ⇒ a source GWN, `sources:` ⇒ a concept/entity/synthesis GWN. Flag any GWN carrying **both**, a source GWN carrying `sources:`, or a non-source GWN carrying `ctn:`.
- Orphan pages (no inbound links from other wiki pages)
- Contradictions between pages
- Stale claims superseded by newer sources
- Concepts mentioned across multiple pages but lacking their own page
- Missing cross-references between clearly related pages
- Data gaps that a web search could fill
- **Cluster coherence** (see AGENTS.md Rule 10):
  - Concepts that span multiple domains but lack explicit wikilinks to all relevant clusters
  - Domains that have grown enough to warrant a new concept page acting as a cluster hub
  - Cluster hub pages with few inbound links — they need to be woven into surrounding pages
  - Any domain cluster that has no synthesis page yet despite 3+ related sources

Produce a prioritized issue list. Ask the human which to fix first, then fix them.
