# Obsidian Vault Setup Checklist

_The customized Obsidian app settings and plugins each wiki vault depends on. These are distinct from the Claude Code bootstrap steps in [[1_agentic_config/admin/checklist.new-wiki-project]] — this file covers the Obsidian-side configuration the schema's conventions quietly assume._

---

## 1. Core Settings — Files & Links

Settings → **Files & Links**:

| Setting | Value | Why |
|---|---|---|
| Use `[[Wikilinks]]` | **ON** | The schema links everything with `[[wikilink]]` syntax, not Markdown `[](…)` links. |
| New link format | **Shortest path when possible** | Matches the schema's short-form link convention — Obsidian generates bare basenames and only lengthens a path when one is needed to disambiguate. |
| Detect all file extensions | **ON** | Lets `[[file.ext]]` resolve to *any* file type in the vault, not just Markdown plus the default attachment types. Required for artifact links to exotic types. |

**Why "Detect all file extensions" matters here:** the schema's link-form rule is *notes use bare basenames; file artifacts in `assets/` carry their true extension* (`.md`, `.json`, `.yaml`, `.py`, `.png`, `.pdf`, and so on). Obsidian only makes the non-default extensions linkable when this toggle is on. With it off, `[[config.yaml]]` and `[[setup.py]]` would render as dead links. See the link-form rule in `AGENTS.md`.

---

## 2. Community Plugin — Local REST API with MCP

Required for the ingest workflow (set the active file, trigger "Download attachments for current file"). The full per-vault setup — install, port assignment, API key, `claude mcp add` registration — is documented in [[setup.obsidian-MCP]]. **Set it up according to that spec.**

---

## 3. Daily Notes → `2_using_timeline/`

Route Obsidian's daily notes into the ingest landing zone so they follow the same workflow as any other source. Configured via `.obsidian/daily-notes.json` or Settings → Daily notes. See Step 4 of [[1_agentic_config/admin/checklist.new-wiki-project]] for the exact configuration.

---

## 4. Web Clipper

The Obsidian Web Clipper deposits clips into the currently focused vault window. The clip's `title:` is pulled from the browser tab — rename the tab to something meaningful *before* clipping if you want a specific title. Multi-vault routing behavior: see Web Clipper Routing in [[setup.obsidian-MCP]].

**Strip the `wikilink` filter from the `author` property.** The Web Clipper's default template formats the author with a `wikilink` filter — `{{author|split:", "|wikilink|join}}` — which wraps every author name in `[[ ]]`. Because no author note exists in the vault, that drops a **dangling `[[Author Name]]` into the frontmatter of every clip** — an orphan link / phantom node. Reconfigure the `author` property (in the Web Clipper template's **Properties** section) to emit **plain text** instead:

- **List method (recommended — robust for multi-author):** property type **List**, template value `{{author|split:", "}}`. Emits a clean list of plain-text names (`author:` → `- D. Brian Blank`), keeping multiple authors as discrete items.
- **Text method (simplest):** property type **Text**, template value `{{author}}`. Emits a single plain-text string.

Both do the same essential thing — **remove the `wikilink` filter**, the part that generates the brackets. The author is then captured as **data**, not a vault link. During ingest the wiki agent promotes notable authors to **entity pages**, so "what else has this author written that I've saved?" is answered by the wiki graph (entity backlinks), not by fragile links in clip frontmatter.
