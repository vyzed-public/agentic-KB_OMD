# Obsidian MCP Setup

_How to wire the Obsidian Local REST API plugin into Claude Code so the wiki agent can trigger Obsidian commands (e.g., "Download attachments for current file")._

---

## Architecture: Multi-Vault, Multi-Port

This works exactly like running multiple Jupyter notebook servers — each vault gets its own port, its own API key, and its own named MCP server entry in Claude Code. All vaults are available simultaneously; there is no switching or key-swapping required.

| Component | Scope | Notes |
|---|---|---|
| Plugin install + enable | **Per-vault** | Community Plugins are configured independently in each vault |
| Port | **Per-vault** | Configure a unique port in each vault's plugin settings (default: 27124) |
| API key | **Per-vault** | Each vault generates its own key |
| `claude mcp add` entry | **Per-vault** | Use a distinct name per vault (e.g. `obsidian-wiki1`, `obsidian-wiki2`) |

All registered MCP servers load at session start. As long as Obsidian is open with those vaults active, all their tools are available simultaneously.

### Web Clipper Routing

The Obsidian web clipper deposits content into whichever vault window is currently focused. In a multi-vault workflow, this means you can route clips to the correct wiki simply by focusing the right Obsidian window before clipping — no configuration needed.

---

## Why This Is Annoying

There are three independent moving parts that must all be true simultaneously, **per vault**:

1. **Obsidian is open** with that vault active — the plugin only runs while the app is active.
2. **The plugin is installed and enabled in that vault** — Community Plugins → Local REST API with MCP, toggle on.
3. **Claude Code has a matching MCP registration** — correct port and API key, registered via `claude mcp add`.

None of these states are visible to the other. If any one is missing, that vault's MCP tools simply don't appear — no error, no warning.

Additionally, **MCP servers added mid-session don't load until Claude Code is restarted**. So after any `claude mcp add`, you must `/exit` and relaunch before the tools are available.

---

## Setup (Per Vault)

Repeat these steps for every vault you want available via MCP.

### Step 1 — Install the plugin (or confirm it's already there)

> **If this vault was cloned from the framework repo, the plugin already ships with it** — installed and enabled on first open (the framework tracks `.obsidian/plugins/obsidian-local-rest-api/` on purpose). Just confirm it's enabled and **skip to Step 2**. Only a from-scratch vault needs a manual install.

To install manually: Obsidian → **Settings → Community Plugins → Browse**, search for **"Local REST API"**, install, enable. Use **"Local REST API with MCP"** specifically (not the older plain "Local REST API"). Confirm the MCP endpoint appears in the plugin settings.

### Step 2 — Assign a unique port

Every vault's plugin defaults to **27124**, so a second vault **will collide** unless you change it. **Don't track ports by hand** — ask the registry for the next free one:

```bash
bash 1_agentic_config/scripts/next-obsidian-port.sh
```

It reads your Claude Code MCP registrations (the durable record of every assigned port) plus anything currently listening, lists the ports **in use**, and prints the **next free port** and the exact `claude mcp add` line for Step 4. Set the plugin to that port in its settings. *(Or ask Claude: "what's the next free Obsidian port?")*

Convention: ports climb from **27124** (first vault) — but let the helper pick, don't count in your head.

### Step 3 — Get the API key

Obsidian → Settings → Local REST API with MCP → copy the **API Key**.

### Step 4 — Register the MCP server with Claude Code

```bash
claude mcp add --transport http obsidian-<vaultname> https://127.0.0.1:<PORT>/mcp/ \
  --header "Authorization: Bearer <API_KEY>" \
  -s user
```

Use a stable, short name for `obsidian-<vaultname>` — it becomes the tool namespace Claude Code uses to identify which vault's tools are which.

### Step 5 — Restart Claude Code

MCP servers only load at session start. `/exit`, then relaunch with `claude`.

---

## Per-Session Prerequisite

For each vault whose MCP tools you need:

- Obsidian must be **open with that vault** before starting Claude Code.
- The plugin must remain **enabled** — it can be disabled by Obsidian's safe-mode or a plugin update.

The wiki agent checks MCP server status at the start of every ingest (per CLAUDE.md). If the tools are unavailable, it will stop and tell you before proceeding.

---

## Credentials

One row per configured vault. Add a row here whenever a new vault is set up.

| Name | Vault | Port | API Key |
|---|---|---|---|
| `obsidian` | `a-a.wiki.test1` | 27124 | `<paste your key locally; NEVER commit a real key to a shared repo>` |

- **Endpoint pattern**: `https://127.0.0.1:<PORT>/mcp/`
- **Config location**: `~/.claude.json` (user scope)

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| A vault's MCP tools missing from ToolSearch | Obsidian not open with that vault, or Claude Code not restarted after `mcp add` |
| Tools present but commands fail | Plugin disabled, Obsidian in restricted mode |
| `mcp add` succeeds but tools still absent after restart | Check `claude mcp list` — server may have a connection error; verify port matches plugin settings |
| Self-signed cert errors | The plugin uses `https://` on localhost; Claude Code must accept the self-signed cert |
| Port conflict on startup | Two vault plugins configured for the same port — assign unique ports in each vault's plugin settings |
