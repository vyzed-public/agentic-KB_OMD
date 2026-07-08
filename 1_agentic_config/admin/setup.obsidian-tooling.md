# Obsidian Tooling Setup

_The command-line tools, plugin, and skills the wiki agent uses. **Most ship with your clone** — you only confirm they're present. Only the two CLI **binaries** are per-machine, one-time installs. (The previous Local REST API / MCP setup has been **retired** — see [[HISTORY.explored-and-retired]] for why.)_

---

## What ships with the clone (confirm — do not reinstall)

Tracked in the framework repo, so a fresh clone already has them:

- **Repeat plugin** ([`prncc/obsidian-repeat-plugin`](https://github.com/prncc/obsidian-repeat-plugin), v2.0.0) — `.obsidian/plugins/repeat-plugin/`. Spaced review of *filed* sources via the `repeat:` frontmatter field. Confirm enabled: Settings → Community Plugins → **Repeat** toggled on. *(Optional feature — leave off if you don't want review scheduling; the `repeat:` field simply lies dormant.)*
- **Claude skills** — `.claude/skills/`: `obsidian-cli/`, `obsidian-bases/`, `defuddle/` (each a `SKILL.md`; MIT © Steph Ango / kepano, from [`kepano/obsidian-skills`](https://github.com/kepano/obsidian-skills)). Claude reads them on demand — nothing to enable. Confirm: `ls .claude/skills/`.

If any are missing, the clone didn't come through cleanly — re-clone per [[checklist.new-wiki-project]] §0.

---

## Per-machine binaries (one-time install)

System binaries the skills drive; they do **not** travel with a vault clone.

### Obsidian CLI
The official `obsidian` CLI gives the agent **authoritative graph queries** — `unresolved` (dangling links), `orphans`, `backlinks` — used during `lint`, plus general vault operations. It's what replaced MCP's one genuinely valuable capability. **No ports or API keys** (unlike the retired MCP path), but it is **built into the Obsidian desktop app** and enabled from inside it — *not* an `npm`/package install. Official docs: https://help.obsidian.md/cli

**Install (one-time):**
1. **Obsidian 1.12.7+ is required** (the CLI ships with the 1.12 installer). Check **Settings → About**; if older, update via the official installer. *(If you installed Obsidian via Flatpak/Snap and step 2's option is absent, that packaging is likely why — reinstall from the official installer.)*
2. **Enable it:** Obsidian → **Settings → General → Command line interface** → enable, then follow the **registration** prompt.
3. **Linux:** registration copies the `obsidian` binary to **`~/.local/bin`** — ensure that directory is on your `PATH`. *(macOS symlinks `/usr/local/bin/obsidian` and asks for admin approval; Windows adds a terminal redirector.)*
4. **Restart your terminal** so the updated `PATH` takes effect.

**Verify** (Obsidian must be **running** — the CLI talks to the live app, launching it if closed):
```bash
obsidian help                            # lists commands
obsidian backlinks file="<some note>"    # authoritative backlinks
```

**Flatpak / Snap install? You need a one-time socket bridge.** If `obsidian help` prints **"unable to find Obsidian"** even with the app running, your Obsidian is **sandboxed**. The CLI looks for its socket at `$XDG_RUNTIME_DIR/.obsidian-cli.sock`, but the sandboxed app creates it in its *private* run dir — for Flatpak: `/run/user/$UID/.flatpak/md.obsidian.Obsidian/xdg-run/.obsidian-cli.sock`. Bridge the two with a symlink. Because `/run/user/$UID` is **tmpfs** (wiped every reboot), it can't be a permanent file — recreate it at login with one guarded line appended to **`~/.profile`**:

```sh
# Obsidian CLI ⇄ Flatpak socket bridge — recreated at login (tmpfs is wiped each boot).
# The [ -d ... ] guard runs it ONLY when the Obsidian Flatpak is installed, so a
# native install is never touched and it's a no-op if you switch/uninstall.
[ -d "$HOME/.var/app/md.obsidian.Obsidian" ] && \
  ln -sf "/run/user/$(id -u)/.flatpak/md.obsidian.Obsidian/xdg-run/.obsidian-cli.sock" \
         "/run/user/$(id -u)/.obsidian-cli.sock" 2>/dev/null
```

- To activate it **now** without logging out, run that same `ln -sf` line once in your shell.
- The wiki agent's **startup check self-heals this symlink**, so a fresh Claude session re-establishes it if it ever goes missing (belt-and-suspenders with the `~/.profile` line).
- **Snap** uses a different run-dir path — adjust the source path accordingly.
- A **native** (non-Flatpak/Snap) Obsidian needs **none** of this: its socket lands at the standard `$XDG_RUNTIME_DIR` path, so the CLI just works. This is the simplest path if you don't need the sandbox. Full rationale for the sandbox quirk: [[HISTORY.explored-and-retired]].

**For the wiki agent to use the CLI:** launch `claude` from a shell that already has `obsidian` on `PATH` (i.e. after the `~/.local/bin` PATH entry — see `~/.profile`). The agent's shells inherit **Claude's launch-time `PATH`**, so a Claude session started *before* the CLI was installed won't see `obsidian` until it's relaunched from a PATH-correct shell. (Fallback: the agent can always call the absolute path `~/.local/bin/obsidian`.)

### Defuddle
A standalone **Node** CLI for clean URL→markdown extraction — preferred over a raw fetch for cluttered web pages (strips nav/ads, saves tokens). **Prerequisite: Node.js / npm** (if `npm` is missing, install Node first).
```bash
npm install -g defuddle
defuddle parse https://example.com --md   # verify
```

---

## Attachments — handled directly (no Obsidian command)

Web clips often carry **remote** images. During ingest the agent **localizes them itself** — fetch → save into `2_using_timeline/YYYY/MM/assets/` → rewrite links to `![[local]]` — via the localizer in `1_agentic_config/scripts/`. Headless, deterministic, needs no Obsidian running. This deliberately replaces the old MCP "Download attachments" command, which could only run through an interactive GUI modal. Full rationale: [[HISTORY.explored-and-retired]].

---

## Web Clipper Routing (multi-vault)

The Obsidian Web Clipper deposits clips into **whichever vault window is currently focused**. With several vaults open, route a clip to the correct wiki simply by focusing that Obsidian window before clipping — no configuration needed.

---

## Preserving a known-good Obsidian version

Obsidian is open-*data* but not open-*source*, and this KB depends on it. To keep a runnable copy of your exact version in case downloads ever vanish, see **[[guide.archive-obsidian]]** (archives the Flatpak bundle + native `.deb`/`.AppImage` into a dated folder under `~/my/installs/`).
