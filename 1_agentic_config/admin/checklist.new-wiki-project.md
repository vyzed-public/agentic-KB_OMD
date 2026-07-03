# New Wiki Project Checklist

Follow this in order for a deterministic setup. Steps marked **(one-time)** only need to be done once per machine — skip them if already in place.

---

## 0. Distribution Model — Template Repo (read first)

This framework is a **template repository**: one repo holds the schema, specs, scripts, and config; each knowledge base is an independent clone of it with its own remote. There are two ways to stand up a vault:

**A. Fork & clone (the normal case) — "fork and keep pulling."** The framework lives once in `agentic-KB_OMD`; each KB is a *fork* you keep pulling framework fixes from, while your content is backed up to your own fork. Full model + recovery: [[spec.git-ops]] and [[RUNBOOK.git-ops]].

1. **Fork** `agentic-KB_OMD` on GitHub; name the fork for your topic (e.g. `akb-omd_astronomy`). The framework repo already ships empty (content dirs hold only `.gitkeep`), so there's nothing to strip.
2. **Clone** your fork locally: `git clone <your-fork-url>`. The local directory name is irrelevant to git (`origin` points at your fork; the guard hook resolves via `$CLAUDE_PROJECT_DIR`), so rename the folder freely.
3. **Run setup once:** `./setup.sh --role vault --upstream <agentic-KB_OMD-url>` — adds `upstream` (fetch-only) so you can pull framework fixes but never push content into the shared framework.
4. Do the **per-vault** steps only: §3 (MCP plugin/port/key) and §4 (daily notes). Then §6–§9.
5. **Everyday:** `git push origin main` backs up your content to your fork; `git pull upstream main` (or GitHub's "Sync fork" button) grabs a framework fix when one ships — your content survives the pull.

**What lives where:**
- **Framework** (schema, `1_agentic_config/`, `AGENTS.md`/`CLAUDE.md`, `.claude/settings.json` with the portable guard hook, `setup.sh`, `.githooks/`) — shared via the framework repo; you *pull* fixes from `upstream`. Framework fixes are published only from a content-free **gateway** clone (see [[spec.git-ops]]).
- **Content** (your ingested notes + generated wiki) — committed to *your own fork's* `origin` (backup + propagation), never pushed to the shared framework. The content-guard hook + push-disabled `upstream` enforce this.
- **Never committed** (gitignored): `.claude/settings.local.json` (personal grants), the **Local REST API key** in `.obsidian/plugins/*/data.json` (per-vault — §3c), and Obsidian per-user UI state.

**B. From scratch (how the template itself was built).** §2 (copy files), §5 (create `settings.json`), and §7 (bootstrap `AGENTS.md`) describe building a vault from nothing — only needed to author a *new* template, not to stand up a KB from an existing one.

The one-time (§1) and per-vault (§3, §4) steps apply to **both** paths.

---

## 1. Global UX Setup (one-time)

Check whether the Claude Code UX setup is already in place:

```bash
ls ~/.claude/statusline-command.sh ~/.claude/title-hook.sh
grep -q "statusLine" ~/.claude/settings.json && echo "settings OK"
```

If any of those are missing, open a Claude session and run:

```
@setup.claude-code-UX.md

Implement this setup exactly as described.
```

---

## 2. Create the New Vault

Create a new directory and open it as an Obsidian vault. Then copy these files from an existing vault's `1_agentic_config/` into the new vault:

- `1_agentic_config/admin/mission.rescue-the-curator.md` ← **the foundational rationale — read it first**; everything else is downstream of the two-value thesis it states
- `1_agentic_config/specs/pattern.karpathy-llm-wiki.md`
- `1_agentic_config/admin/setup.claude-code-UX.md`
- `1_agentic_config/admin/setup.obsidian-MCP.md`
- `1_agentic_config/admin/checklist.new-wiki-project.md` ← this file
- `1_agentic_config/admin/checklist.obsidian.setup.md`

Then apply the Obsidian app-level settings in [[1_agentic_config/admin/checklist.obsidian.setup]] (Wikilinks, link format, Detect all file extensions) and install the plugins it lists.

---

## 3. Obsidian MCP Setup (per vault)

Each vault needs its own plugin instance, port, and MCP registration. See [[setup.obsidian-MCP]] for full details; the short version:

**a. Install and enable the plugin**

Obsidian → Settings → Community Plugins → Browse → **"Local REST API with MCP"** → Install → Enable.

**b. Assign a unique port**

In the plugin settings, set the port. Use the next available in sequence:

| Vault | Port |
|---|---|
| First wiki | 27124 |
| Second wiki | 27125 |
| Third wiki | 27126 |

**c. Get the API key**

Obsidian → Settings → Local REST API with MCP → copy the **API Key**.

**d. Register with Claude Code**

```bash
claude mcp add --transport http obsidian-<vaultname> https://127.0.0.1:<PORT>/mcp/ \
  --header "Authorization: Bearer <API_KEY>" \
  -s user
```

Use a short, stable name for `obsidian-<vaultname>` (e.g. `obsidian-research`, `obsidian-work`).

**e. Record credentials**

Add a row to the credentials table in `1_agentic_config/admin/setup.obsidian-MCP.md` in this vault.

> MCP servers only load at session start — restart Claude Code after registering.

---

## 4. Configure Daily Notes → `2_using_timeline/`

Route Obsidian's daily notes into the `2_using_timeline/` landing zone so they follow the same ingest workflow as any other source file.

Create `.obsidian/daily-notes.json` in the vault with:

```json
{
  "folder": "2_using_timeline",
  "format": "YYYY-MM-DD"
}
```

Or via Obsidian: **Settings → Daily notes → New file location → `2_using_timeline`**, Date format → `YYYY-MM-DD`.

Daily notes land in `2_using_timeline/` root as `YYYY-MM-DD.md` — pending ingest like any other dropped file. After ingest they move to `2_using_timeline/YYYY/MM/`.

**Workflow:** Ingest at end of day when the note is complete. If a collision occurs (note already ingested), the agent renames the duplicate to `_FIX-DUPE_YYYY-MM-DD.md` — a working scrap you can mine for content before deleting from Obsidian.

---

## 5. Set Up the timeline-guard Hook *(from-scratch path only — a template clone already has this)*

Copy `1_agentic_config/scripts/timeline-guard.sh` into the new vault, then create `.claude/settings.json` with:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/1_agentic_config/scripts/timeline-guard.sh\""
          }
        ]
      }
    ]
  }
}
```

**Use `$CLAUDE_PROJECT_DIR`, never an absolute path.** Claude Code sets `$CLAUDE_PROJECT_DIR` to the vault root at runtime, so the hook resolves wherever the vault is dropped and whatever the directory is renamed to — this is what makes the guard survive a para-drop. A hardcoded path silently breaks the guard in every clone (the exact "silent rule-violation" class the schema warns about). See [[1_agentic_config/specs/spec.timeline-guard-hook]] for full details.

---

## 6. Open Claude Code in the New Vault

```bash
cd /path/to/new-vault
claude
```

---

## 7. Bootstrap the Wiki

In the new Claude session, pass this prompt:

```
@pattern.karpathy-llm-wiki.md

You are now my LLM wiki agent for this vault.
Implement this spec as my complete second brain:
- Create AGENTS.md with full schema and rules (and CLAUDE.md as a symlink to it)
- Set up wiki.index.md and 1_agentic_config/logs/ (monthly log file YYYY-MM.md + _agent_logs.md hub)
- Create the folder structure (2_using_timeline/, 3_generates_wiki/sources/, 3_generates_wiki/concepts/, 3_generates_wiki/entities/, 3_generates_wiki/synthesis/)
- Ingest this spec file itself as the first source

From now on, every interaction follows the schema.
```

---

## 8. Confirm Setup

After Claude finishes, verify these files exist:

- [ ] `AGENTS.md` (and `CLAUDE.md` symlink)
- [ ] `wiki.index.md`
- [ ] `1_agentic_config/logs/` (with `_agent_logs.md` hub + current month's `YYYY-MM.md`)
- [ ] `2_using_timeline/`
- [ ] `3_generates_wiki/sources/`
- [ ] `3_generates_wiki/concepts/`
- [ ] `3_generates_wiki/entities/`
- [ ] `3_generates_wiki/synthesis/`
- [ ] `1_agentic_config/scripts/timeline-guard.sh` (executable)
- [ ] `.claude/settings.json` (hook wired)
- [ ] At least one entry in the current month's log file (`1_agentic_config/logs/YYYY-MM.md`)
- [ ] At least one entry in `wiki.index.md`
- [ ] MCP tools reachable (`vault_list` returns this vault's files)

---

## 9. Add Your First Real Source

Drop a file into `2_using_timeline/`, then tell Claude:

```
ingest filename.md
```

---

## You're Live

From here, the three operations are:

| Say this | What happens |
|---|---|
| `ingest filename.md` | Claude reads and integrates a new source |
| Ask any question | Claude searches the wiki and synthesizes an answer |
| `lint` | Claude audits the wiki for gaps and contradictions |
