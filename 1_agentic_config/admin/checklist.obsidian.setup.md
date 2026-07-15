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

## 2. Community Plugin — Repeat (+ vendored skills)

The framework ships the **Repeat** plugin (`.obsidian/plugins/repeat-plugin/`) for spaced review of filed sources, plus the vendored Claude skills in `.claude/skills/`. Just **confirm** the plugin is enabled (Settings → Community Plugins → **Repeat**). Attachments are localized directly by the agent (no plugin), and authoritative graph queries come from the per-machine `obsidian` CLI. Full detail — including the two per-machine CLI installs (`obsidian`, `defuddle`) — is in [[setup.obsidian-tooling]]. *(The old Local REST API / MCP path has been retired — see [[HISTORY.explored-and-retired]].)*

---

## 3. Daily Notes → `2_using_timeline/`

Route Obsidian's daily notes into the ingest landing zone so they follow the same workflow as any other source. Configured via `.obsidian/daily-notes.json` or Settings → Daily notes. See Step 4 of [[1_agentic_config/admin/checklist.new-wiki-project]] for the exact configuration.

---

## 4. Web Clipper

The Obsidian Web Clipper deposits clips into the currently focused vault window. The clip's `title:` is pulled from the browser tab — rename the tab to something meaningful *before* clipping if you want a specific title. Multi-vault routing behavior: see Web Clipper Routing in [[setup.obsidian-tooling]].

**Strip the `wikilink` filter from the `author` property.** The Web Clipper's default template formats the author with a `wikilink` filter — `{{author|split:", "|wikilink|join}}` — which wraps every author name in `[[ ]]`. Because no author note exists in the vault, that drops a **dangling `[[Author Name]]` into the frontmatter of every clip** — an orphan link / phantom node. Reconfigure the `author` property (in the Web Clipper template's **Properties** section) to emit **plain text** instead:

- **List method (recommended — robust for multi-author):** property type **List**, template value `{{author|split:", "}}`. Emits a clean list of plain-text names (`author:` → `- D. Brian Blank`), keeping multiple authors as discrete items.
- **Text method (simplest):** property type **Text**, template value `{{author}}`. Emits a single plain-text string.

Both do the same essential thing — **remove the `wikilink` filter**, the part that generates the brackets. The author is then captured as **data**, not a vault link. During ingest the wiki agent promotes notable authors to **entity pages**, so "what else has this author written that I've saved?" is answered by the wiki graph (entity backlinks), not by fragile links in clip frontmatter.

---
## 4. Additional Customizations

Resolved w/ AI assistance


### Enable `[Control+up/down arrow]`keys
```
I am working right now in Obsidian 
and all of a sudden my control down arrow is not moving selections of text up and down like it should. 
Did I inadvertently hit a setting to disable that key combo?
```

Yes — in Obsidian that kind of shortcut is usually being **overridden by a hotkey or plugin**, not permanently disabled. A common cause is another command being bound to the same key combo, so check **Settings → Hotkeys** and search for the exact combo to see what it’s currently assigned to.[[reddit](https://www.reddit.com/r/ObsidianMD/comments/mytydf/ctrl_shift_hot_key_to_select_multiple_words_not/)]

#### What to check

- Search Hotkeys for `Ctrl+Down` and `Ctrl+Shift+Down` separately, because one may have been reassigned even if the other looks fine.[[forum.obsidian](https://forum.obsidian.md/t/keyboard-shortcut-to-move-selected-rows-up-and-down/6325)]
    
- If you use community plugins, temporarily disable them or start in restricted mode to see whether a plugin is intercepting the arrows.[[forum.obsidian](https://forum.obsidian.md/t/up-down-arrows-dont-work-in-quick-switcher-or-command-menu-with-minimal-theme/33597)]
    
- Also check whether you’re in a special UI area like the command palette, quick switcher, or suggestion list, because those can handle arrow keys differently.[[forum.obsidian](https://forum.obsidian.md/t/ios-up-down-arrows-dont-work-when-selecting-blocks-to-link-with-external-keyboard/59878)]
    
#### Likely fix

If a command is bound to that shortcut, clear the binding and restore the default text-editing behavior. If no binding shows up, a plugin or theme interaction is the more likely culprit than a setting you toggled intentionally.[[reddit](https://www.reddit.com/r/ObsidianMD/comments/mytydf/ctrl_shift_hot_key_to_select_multiple_words_not/)]

---
### Enable wide-screen horizontal span extents

```
In my obsidian session I have minimized my left and right scroll bars, 
but my display area has not taken up the width of my very large monitor. 
Is there a way to make it take up all the room that's available?
```


Yes — the setting you want is **Readable line length**. Turning it **off** lets the note body expand to the full available width of the pane in both editor and preview.[[forum.obsidian](https://forum.obsidian.md/t/fix-large-screen-visualization-for-tables-and-content/111802/2)]

#### Where to change it

- Go to **Settings → Editor → Readable line length**.
    
- Switch it **off** if you want the text area to use the full width of your monitor.[[forum.obsidian](https://forum.obsidian.md/t/how-to-get-a-lager-page-width-in-both-editing-mode-and-preview-mode/7555)]

#### If it still looks narrow

- A CSS snippet or theme setting may be forcing a max width even after you disable readable line length.[[lmika](https://lmika.org/2023/05/18/full-with-notes.html)]
    
- In that case, a snippet like `--file-line-width: 100%` or removing width limits from `.cm-sizer` can restore full-width layout.[[reddit](https://www.reddit.com/r/ObsidianMD/comments/1bpxwuc/is_there_a_way_to_make_the_text_take_the_full/)]
    

#### Extra note

Minimizing sidebars helps, but it does not override the note-width setting by itself; Obsidian can still keep a readable-width column unless you disable that option.[[forum.obsidian](https://forum.obsidian.md/t/fix-large-screen-visualization-for-tables-and-content/111802/2)]