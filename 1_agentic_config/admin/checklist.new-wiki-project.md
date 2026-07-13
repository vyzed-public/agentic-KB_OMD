# Deploy a New Knowledge Base — Checklist

Follow this in order to **deploy** a new knowledge base from the shared framework. You are *deploying*, not building — the framework already exists; you clone it and configure your own copy. Steps marked **(one-time)** only need doing once per machine — skip them if already in place.

---

## 0. Deployment Model — Clone & Keep Pulling (read first)

One framework repo (`agentic-KB_OMD`) holds the schema, specs, scripts, and config. Each knowledge base is its **own independent GitHub repo, cloned from the framework** — so it shares the framework's history (fixes pull in cleanly) while your notes back up to your own repo. Full model + recovery: [[spec.git-ops]] and [[RUNBOOK.git-ops]].

> **⚠ Do NOT use GitHub's "Fork" button or "Use this template."**
> - **Fork:** GitHub allows only **one fork of a repo per account** — you cannot fork the framework once per knowledge base.
> - **Use this template:** creates a repo with *unrelated* git history, which makes `git pull upstream main` fail.
> - **Cloning the framework into your own new repo** (below) avoids both: **unlimited** knowledge bases, and clean framework-fix pulls. This is the only supported path.

### Stand up your knowledge base — just execute, top to bottom

Pick two values, then run each block in order. Nothing to decide.

- `<TOPIC>` — your KB's subject, e.g. `astronomy`
- `<OWNER>` — your GitHub username or org, e.g. `vyzed-public`

**A1 · Make an empty GitHub repo.** Fastest from the CLI — one command, no browser, and it creates a **zero-commit** repo (what A2 needs). *(Prereq: `gh` installed and authenticated — check with `gh auth status`.)*

```bash
gh repo create <OWNER>/akb-omd_<TOPIC> --private --description "<your description>"
```

Use `--public` for a public repo; omit `--description` if you don't want one. Success prints `✓ Created repository … on GitHub`.

Examples :

```
gh repo create dpcunningham/akb-omd_AI-lightcone --private --description "An agentic knowledge base for a user's \"light cone\" experience of AI topic discovery"
gh repo create dpcunningham/akb-omd_tradeNvest --private --description "An agentic knowledge base for developing trading & investing strategies"
```

**⚠ Do NOT** add a README, license, or .gitignore — the repo must have **zero commits**, or the initial commit collides with the framework history you push in A2. `gh repo create` (without `--clone`/`--source`) makes an empty repo by default, so you're fine.

> **Alternative — GitHub web UI:** New repository → name it `akb-omd_<TOPIC>` → **do not** check "Add a README," ".gitignore," or "license" (any creates a colliding initial commit); description/topics/visibility are fine (metadata, not commits). An empty repo shows the **"Quick setup"** page with no green "Code" button — that's correct; grab the HTTPS URL there. The normal repo view returns after A2's `git push`.

**A2 · Clone the framework into it and publish** — paste as-is, with `<TOPIC>` / `<OWNER>` substituted:

```bash
git clone https://github.com/vyzed-public/agentic-KB_OMD.git akb-omd_<TOPIC>
cd akb-omd_<TOPIC>
git remote set-url origin https://github.com/<OWNER>/akb-omd_<TOPIC>.git
git push -u origin main
```

Examples: 
```
git clone https://github.com/vyzed-public/agentic-KB_OMD.git akb-omd_AI-lightcone
git clone https://github.com/vyzed-public/agentic-KB_OMD.git akb-omd_tradeNvest

cd akb-omd_AI-lightcone
git remote set-url origin https://github.com/dpcunningham/akb-omd_AI-lightcone.git
git push -u origin main

cd ../akb-omd_tradeNvest/
git remote set-url origin https://github.com/dpcunningham/akb-omd_tradeNvest.git
git push -u origin main
```


**A3 · Wire the update link** — adds `upstream` = the framework, **fetch-only** (so your content can never be pushed into the shared framework):

```bash
./setup.sh --role vault --upstream https://github.com/vyzed-public/agentic-KB_OMD.git
```

Examples :
```
dpc:~/.../kbs.agent-automated.wikis$ cd akb-omd_AI-lightcone/

dpc:~/.../akb-omd_AI-lightcone$ # Wire an update link to add the framework as an additional upstream READ-ONLY repo (where our content can never be pushed):

dpc:~/.../akb-omd_AI-lightcone$ ./setup.sh --role vault --upstream https://github.com/vyzed-public/agentic-KB_OMD.git
vault ready: upstream -> https://github.com/vyzed-public/agentic-KB_OMD.git (push DISABLED).
  back up your content:   git push origin main
  pull framework fixes:   git pull upstream main

dpc:~/.../akb-omd_AI-lightcone$ git remote -v
origin	https://github.com/dpcunningham/akb-omd_AI-lightcone.git (fetch)
origin	https://github.com/dpcunningham/akb-omd_AI-lightcone.git (push)
upstream	https://github.com/vyzed-public/agentic-KB_OMD.git (fetch)
upstream	DISABLED (push)

dpc:~/.../akb-omd_AI-lightcone$ cd ../akb-omd_tradeNvest/

dpc:~/.../akb-omd_tradeNvest$ ./setup.sh --role vault --upstream https://github.com/vyzed-public/agentic-KB_OMD.git
vault ready: upstream -> https://github.com/vyzed-public/agentic-KB_OMD.git (push DISABLED).
  back up your content:   git push origin main
  pull framework fixes:   git pull upstream main
 
dpc:~/.../akb-omd_tradeNvest$ git remote -v
origin	https://github.com/dpcunningham/akb-omd_tradeNvest.git (fetch)
origin	https://github.com/dpcunningham/akb-omd_tradeNvest.git (push)
upstream	https://github.com/vyzed-public/agentic-KB_OMD.git (fetch)
upstream	DISABLED (push) 
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

**A5 · Finish deploying.** Work through the rest of this checklist: **§2** (open the cloned folder as an Obsidian vault), **§3** (Obsidian tooling — CLI, plugin, skills), **§4** (daily notes), **§5** (open Claude Code), **§6** (confirm), **§7** (add your first source).

**Everyday, from then on — just two commands:**

| Run this | What it does |
|---|---|
| `git push origin main` | Backs up *your content* to *your own* repo |
| `git pull upstream main` | Pulls a framework fix when one ships — **your content survives the merge** |

**What lives where:**
- **Framework** (schema, `1_agentic_config/`, `AGENTS.md`/`CLAUDE.md`, `.claude/settings.json` with the portable guard hook, `.claude/skills/` (vendored Obsidian skills), `.obsidian/plugins/repeat-plugin/`, `setup.sh`, `.githooks/`) — shared; you *pull* fixes from `upstream`. Framework fixes are published only from a content-free **gateway** clone (see [[spec.git-ops]]) — you never push into the shared framework.
- **Content** (your ingested notes + generated wiki) — committed to *your own* repo's `origin` (backup + propagation). The push-disabled `upstream` enforces this.
- **Never committed** (gitignored): `.claude/settings.local.json` (personal grants) and Obsidian per-user UI state.

---

## 0.5 Optional — Encrypt This Vault's Content (choose a privacy tier)

> **⏳ PLANNED — the enabling tooling is not yet shipped.** This documents the *decision* you make at deploy time; the one-command `git-crypt` enablement lands in a future release. For now, deploy Tier 0 (private) and revisit when the tooling ships — or enable Tier 1 manually per [[spec.content-encryption]].

Content vaults hold your (potentially sensitive) notes. The **framework repo is never encrypted** — this is a per-*content-vault* choice, made **before the first content commit** (retrofitting onto plaintext history is a painful rewrite). Pick ONE tier:

| Tier | What protects your content | Filenames hidden? | Cost |
|---|---|---|---|
| **0 — Private only** | GitHub-private repo (access control) | No | none |
| **1 — Content-encrypted** | git-crypt encrypts note bodies + images at rest | **No** — titles/dates/names still visible | ~none |
| **2 — Fully opaque** | git-remote-gcrypt (contents + filenames + history) | Yes | high (remote not browsable) |

**How to choose:** are only the *contents* sensitive, or the *titles / dates / entity-names* too? Contents only → **Tier 1**. Titles themselves are secret → **Tier 2**. Neither → **Tier 0**. Full detail — the filename limitation, key management, and operating rules — is in **[[spec.content-encryption]]**.

> **⚠ CRITICAL — an encrypted vault MUST be single-writer.** Encryption stores notes as binary blobs that git **cannot merge.** Editing the same encrypted note on two machines before syncing can produce an unresolvable ciphertext conflict that **scrambles or destroys the note — a catastrophic, often unrecoverable loss.** If you choose Tier 1 or 2 you **must pull before editing and push right after**, and never edit the vault on a second machine until the first has pushed. Cannot guarantee that? **Choose Tier 0.** Full rule: [[spec.content-encryption]].

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

The clone already contains *everything* — the framework files, the `.obsidian/` app settings, the **Repeat** plugin, and the vendored Claude skills. There is **nothing to copy or assemble.** You just point Obsidian at the folder:

- Obsidian → the **vault switcher** (bottom-left, the current vault's name) → **Manage vaults…** → **Open folder as vault** → pick your cloned `akb-omd_<TOPIC>` directory. *(On a fresh Obsidian launch, the "Manage vaults" window offers **Open folder as vault** directly.)*

Because the framework ships the Obsidian app settings and the plugin, they're already in place — you do **not** re-apply [[checklist.obsidian.setup]] or install anything. Skim that doc only if something looks off.

---

## 3. Obsidian Tooling Setup

The wiki agent uses a small set of Obsidian tools. **Most ship with your clone** — you just confirm they're present. Only the two command-line **binaries** are per-machine, one-time installs. There are **no ports, keys, or registrations** — that whole apparatus (the retired MCP/Local-REST-API path) is gone; see [[HISTORY.explored-and-retired]] for why.

Full detail: [[setup.obsidian-tooling]]. The short version:

**a. Confirm the shipped tools are present** (they travel with the clone — do **not** reinstall):

```bash
ls .claude/skills/          # expect: obsidian-cli/  obsidian-bases/  defuddle/
```
And in Obsidian → Settings → Community Plugins → confirm **Repeat** is listed and toggled on. *(Optional — it powers spaced review of filed sources via `repeat:`. Leave off if you don't want it.)* If the skills folder or plugin is missing, the clone didn't come through cleanly — re-clone per §0.

**b. Enable the Obsidian CLI (one-time, per machine).** Used for authoritative graph queries during `lint` (`unresolved`/`orphans`/`backlinks`). It's **built into the desktop app** (Obsidian **1.12.7+**) — *not* an `npm`/package install: enable it via **Settings → General → Command line interface** and follow the registration prompt (on Linux the binary lands in `~/.local/bin` — ensure it's on your `PATH` — then restart your terminal). Full steps + gotchas: [[setup.obsidian-tooling]]. With Obsidian **running**, verify:

```bash
obsidian help
obsidian backlinks file="<some note>"
```

No ports, no keys. *(Flatpak/Snap Obsidian? `obsidian help` may report "unable to find Obsidian" even when it's running — the sandbox hides the CLI socket. Fix: the one-time `~/.profile` socket bridge in [[setup.obsidian-tooling]].)*

**c. Install Defuddle (one-time, per machine).** Clean URL→markdown extraction, used when the agent fetches a web page directly:

```bash
npm install -g defuddle
defuddle parse https://example.com --md   # verify
```

That's the whole setup — no per-vault configuration at all.

---

## 4. Confirm Daily Notes → `2_using_timeline/`

Obsidian's daily notes route into the `2_using_timeline/` landing zone so they flow through the same ingest workflow as any other source file.

**This should already be set by virtue of the repo** — `.obsidian/daily-notes.json` is tracked in the framework, so it travels with your clone (**New file location** = `2_using_timeline`, **Date format** = `YYYY-MM-DD`). So normally this is just a **confirm** — nothing to do.

**If for some reason it didn't come through**, set it the normal Obsidian way — through **Settings**, not by editing files (the `.obsidian/` folder is hidden and isn't reachable from Obsidian's file explorer anyway):

- Obsidian → **Settings → Daily notes** *(a core plugin — already enabled in your clone)*
- **New file location** → `2_using_timeline`
- **Date format** → `YYYY-MM-DD`

Daily notes land in `2_using_timeline/` root as `YYYY-MM-DD.md` — pending ingest like any other dropped file. After ingest they move to `2_using_timeline/YYYY/MM/`.

**Workflow:** Ingest at end of day when the note is complete. If a collision occurs (note already ingested), the agent renames the duplicate to `_FIX-DUPE_YYYY-MM-DD.md` — a working scrap you can mine for content before deleting from Obsidian.

---

## 5. Start Claude Code in the Vault

Now — and only now — start Claude Code from inside the vault:

```bash
cd /path/to/your-vault
claude
```

You're now inside the interactive Claude Code CLI, with the vendored skills available on demand.

---

## 6. Confirm the Deployment

Your clone brought the whole framework; confirm it arrived intact and the tooling is present:

- [ ] `AGENTS.md` (and `CLAUDE.md` symlink → `AGENTS.md`)
- [ ] `wiki.index.md`
- [ ] `1_agentic_config/logs/` (with the `_agent_logs.md` hub)
- [ ] `2_using_timeline/` and `3_generates_wiki/{sources,concepts,entities,synthesis}/`
- [ ] `1_agentic_config/scripts/timeline-guard.sh` (executable)
- [ ] `.claude/settings.json` (guard hook wired via `$CLAUDE_PROJECT_DIR`)
- [ ] `.claude/skills/` contains `obsidian-cli/`, `obsidian-bases/`, `defuddle/`
- [ ] `obsidian help` works (CLI installed; Obsidian running)

---

## 7. Add Your First Real Source

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
