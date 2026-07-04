# New Wiki Project Checklist

Follow this in order for a deterministic setup. Steps marked **(one-time)** only need to be done once per machine — skip them if already in place.

---

## 0. Distribution Model — Clone & Keep Pulling (read first)

One framework repo (`agentic-KB_OMD`) holds the schema, specs, scripts, and config. Each knowledge base is its **own independent GitHub repo, cloned from the framework** — so it shares the framework's history (fixes pull in cleanly) while your notes back up to your own repo. Full model + recovery: [[spec.git-ops]] and [[RUNBOOK.git-ops]].

> **⚠ Do NOT use GitHub's "Fork" button or "Use this template."**
> - **Fork:** GitHub allows only **one fork of a repo per account** — you cannot fork the framework once per knowledge base.
> - **Use this template:** creates a repo with *unrelated* git history, which makes `git pull upstream main` fail.
> - **Cloning the framework into your own new repo** (below) avoids both: **unlimited** knowledge bases, and clean framework-fix pulls. This is the only supported path.

### A. Stand up a new knowledge base — just execute, top to bottom

Pick two values, then run each block in order. Nothing to decide.

- `<TOPIC>` — your KB's subject, e.g. `astronomy`
- `<OWNER>` — your GitHub username or org, e.g. `vyzed-public`

**A1 · Make an empty GitHub repo.** Name it `akb-omd_<TOPIC>`. The repo must have **zero commits**, so **do not** check "Add a README," ".gitignore," or "license" — any of those creates an initial commit that collides with the framework history you push in A2. A **description**, **topics**, and the **public/private** choice are all fine — they're repo metadata, not commits.

> **Expected, not an error:** an empty repo shows GitHub's **"Quick setup"** page instead of the normal code view — **there is no green "Code"/clone button yet, and that's correct** (nothing to clone until you push). Grab the repo URL from the HTTPS box on that page. Ignore GitHub's "We recommend every repository include a README, LICENSE, and .gitignore" nudge — the framework history you push in A2 already brings its own. The normal repo view returns right after A2's `git push`.

**A2 · Clone the framework into it and publish** — paste as-is, with `<TOPIC>` / `<OWNER>` substituted:

```bash
git clone https://github.com/vyzed-public/agentic-KB_OMD.git akb-omd_<TOPIC>
cd akb-omd_<TOPIC>
git remote set-url origin https://github.com/<OWNER>/akb-omd_<TOPIC>.git
git push -u origin main
```

**A3 · Wire the update link** — adds `upstream` = the framework, **fetch-only** (so your content can never be pushed into the shared framework):

```bash
./setup.sh --role vault --upstream https://github.com/vyzed-public/agentic-KB_OMD.git
```

**A4 · Confirm the wiring.** Run:

```bash
git remote -v
```

You should see exactly these four lines (with your `<OWNER>`/`<TOPIC>`):

```
origin    https://github.com/<OWNER>/akb-omd_<TOPIC>.git (fetch)
origin    https://github.com/<OWNER>/akb-omd_<TOPIC>.git (push)
upstream  https://github.com/vyzed-public/agentic-KB_OMD.git (fetch)
upstream  DISABLED (push)
```

`origin` = **your** repo, `upstream` = **the framework**, and `upstream`'s **push is DISABLED**. Then open your repo's GitHub page — it should now show the framework files (not the empty quick-setup page).

> **⚠ Check the repo name matches character-for-character.** A one-letter difference (e.g. `AI-lightcone` vs `AI-light-cone`) points `origin` at a *different* repo and silently splits your work across two — and `git push` won't warn you if that other name also happens to exist. If the name is wrong, fix it: `git remote set-url origin <correct-url>` then `git push -u origin main`, and delete the stray empty repo on GitHub.

**A5 · Finish the vault.** Then **§2** (open the cloned folder as an Obsidian vault), **§3** (Obsidian MCP — port/key/registration), **§4** (daily notes), and **§6, §8, §9**. **Skip §5 and §7** (from-scratch only) — a clone already has the guard hook and a bootstrapped wiki.

**Everyday, from then on — just two commands:**

| Run this | What it does |
|---|---|
| `git push origin main` | Backs up *your content* to *your own* repo |
| `git pull upstream main` | Pulls a framework fix when one ships — **your content survives the merge** |

**What lives where:**
- **Framework** (schema, `1_agentic_config/`, `AGENTS.md`/`CLAUDE.md`, `.claude/settings.json` with the portable guard hook, `setup.sh`, `.githooks/`) — shared; you *pull* fixes from `upstream`. Framework fixes are published only from a content-free **gateway** clone (see [[spec.git-ops]]).
- **Content** (your ingested notes + generated wiki) — committed to *your own* repo's `origin` (backup + propagation), never pushed to the shared framework. The push-disabled `upstream` enforces this.
- **Never committed** (gitignored): `.claude/settings.local.json` (personal grants), the **Local REST API key** in `.obsidian/plugins/*/data.json` (per-vault — §3c), and Obsidian per-user UI state.

### B. From scratch (only to author a *new* framework, not a knowledge base)

§2 (copy files), §5 (create `settings.json`), and §7 (bootstrap `AGENTS.md`) describe building a vault from nothing — needed only to create a brand-new framework, not to stand up a KB from the existing one.

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

## 2. Open the Vault in Obsidian

**Cloned vault (§0 path A — the normal case):** the clone already contains *everything* — the framework files, the `.obsidian/` app settings, and the MCP plugin. There is **nothing to copy or assemble.** You just point Obsidian at the folder:

- Obsidian → the **vault switcher** (bottom-left, the current vault's name) → **Manage vaults…** → **Open folder as vault** → pick your cloned `akb-omd_<TOPIC>` directory. *(On a fresh Obsidian launch, the "Manage vaults" window offers **Open folder as vault** directly.)*

Because the framework ships the Obsidian app settings and the plugin, they're already in place — you do **not** re-apply [[checklist.obsidian.setup]] or install anything. Skim that doc only if something looks off.

> **From-scratch path only (§0 path B — authoring a _new_ framework):** there's no clone to open, so instead create an empty directory, open it as a vault, then assemble the framework by hand — copy these seed files from an existing vault's `1_agentic_config/`, and apply the app settings in [[checklist.obsidian.setup]] (Wikilinks, link format, Detect all file extensions) + install the plugins it lists:
> - `1_agentic_config/admin/mission.rescue-the-curator.md` ← the foundational rationale — read it first
> - `1_agentic_config/specs/pattern.karpathy-llm-wiki.md`
> - `1_agentic_config/admin/setup.claude-code-UX.md`
> - `1_agentic_config/admin/setup.obsidian-MCP.md`
> - `1_agentic_config/admin/checklist.new-wiki-project.md`
> - `1_agentic_config/admin/checklist.obsidian.setup.md`

---

## 3. Obsidian MCP Setup (per vault)

> **📦 Heads-up — the plugin ships with the clone. This is intentional, not a mistake.**
> The framework repo deliberately tracks the **"Local REST API with MCP"** plugin code in `.obsidian/plugins/obsidian-local-rest-api/`, so a vault you cloned per §0 **already has the plugin installed and enabled** the first time you open it. That's the "para-drop and go" design. **Do not be surprised to see it already there, and do not reinstall it.**
>
> What does **not** ship (it's gitignored) is the plugin's `data.json` — which holds this vault's **port and API key**. So those two, plus the one-time MCP registration, are the *only* genuinely per-vault steps. That's exactly what a–e below cover.

See [[setup.obsidian-MCP]] for full details; the short version:

**a. Confirm the plugin is enabled** *(cloned vault)* — or **install it** *(from-scratch vault only)*

A vault cloned per §0 already ships **"Local REST API with MCP"** enabled — just confirm: Obsidian → Settings → Community Plugins → it's listed and toggled on. Only if it's *absent* (from-scratch path): Browse → **"Local REST API with MCP"** → Install → Enable.

**b. Assign a unique port** — ⚠ **required; a clone defaults to 27124 and will collide**

Because `data.json` didn't travel, the plugin comes up on the **default port 27124** — the *same as your first vault* — so you must change it. **Don't guess, and don't try to remember which ports you've already used.** Ask the registry:

```bash
bash 1_agentic_config/scripts/next-obsidian-port.sh
```

It reads your Claude Code MCP registrations (the durable record of every vault's port) plus anything currently listening, prints the ports **in use**, and hands you the **next free one** — along with the exact `claude mcp add` line for step d. Set the plugin to that port: Obsidian → Settings → Local REST API with MCP → **Port**.

*(Or simply ask Claude — "what's the next free Obsidian port?" — it runs the same check and tells you.)*

**c. Get the API key**

On first enable, the plugin generates **this vault's own** key into `data.json` (gitignored — it never shipped, so it is *not* another vault's key). Copy it: Obsidian → Settings → Local REST API with MCP → **API Key**.

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
