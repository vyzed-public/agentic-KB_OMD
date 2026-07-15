---
title: Content-Vault Encryption
created: 2026-07-09
updated: 2026-07-09
status: PLANNED — the three-tier model is decided; the enabling tooling (enable-encryption.sh) is NOT yet shipped. Tier 1 can be enabled manually today (see "Enable Tier 1 manually" below).
description: Optional at-rest encryption for a CONTENT vault's notes, so they are opaque in the vault's own GitHub origin. Three privacy tiers chosen per-vault at deploy time. The framework repo is NEVER encrypted.
---

# Content-Vault Encryption

> **⏳ PLANNED.** The privacy-tier *model* below is decided and stable — use it to choose a tier now. The one-command enablement (`enable-encryption.sh`) is not yet shipped; Tier 1 can be enabled manually (steps at the bottom). Full rationale, threat model, and the open Tier-2 decision live in the dev design doc `DESIGN.content-vault-encryption.md` (not shipped with clones).

## ⚠ CRITICAL operating risk — concurrent edits can CORRUPT an encrypted vault

**Read this before enabling ANY encryption (Tier 1 or 2).** Encryption stores your notes as **binary blobs** in git, and **git cannot 3-way-merge binary content.** With plaintext notes git silently auto-merges edits made on two machines; once encrypted, **that safety net is gone for all content.**

**The failure mode:** the *same* note edited on two machines (or by two people) before syncing produces a merge conflict git **cannot** auto-resolve — and because both sides are ciphertext, **you cannot hand-merge them by reading them.** A careless resolution or a force-push then **scrambles or destroys the note.** For a knowledge base this is a **catastrophic, often unrecoverable data-loss event**, not a routine conflict.

**Mandatory operating rule for any encrypted vault:**
- Treat an encrypted vault as **single-writer at a time. Pull before you edit; push right after.** Never edit the vault on a second machine until the first has pushed.
- If a conflict on an encrypted file ever appears, **do NOT guess-resolve it.** Stop, restore the file from the last-known-good commit (or the other machine's clean copy), then re-apply your change deliberately.
- This discipline is the **price of encryption.** If you cannot guarantee serialized single-writer access, prefer **Tier 0 (private, unencrypted)** — which keeps git's automatic text merge.

---

## Scope — content vaults only, never the framework

Encryption applies to a **content vault** (`akb-omd_<TOPIC>`), so a user's potentially sensitive notes are opaque at rest in **their own** GitHub `origin`. The shared **framework repo (`agentic-KB_OMD`) is never encrypted** — it is public and non-sensitive, and encrypting it would break the public-framework model and every downstream `git pull upstream`.

This is the same content/framework boundary the content-guard hook enforces, from the other side: the guard keeps content *out of the framework repo*; encryption keeps content *opaque in the vault's own repo*. The canonical "what is content" list — `1_agentic_config/scripts/content-paths` — is the single source of truth for **what gets encrypted**, so the two never drift.

## Why not just "make the repo private"?

A private repo stops anonymous public browsing. Encryption additionally defends against: GitHub-the-company / subpoenas, a compromised account or token, an accidental public-flip, a rogue collaborator, and leaked backups. It is **optional defense-in-depth** — only worth the cost if those threats are in your model.

## The three tiers — choose ONE per vault, at deploy time

| Tier | Mechanism (extra binary?) | Protects at rest | Filenames hidden? | Install / setup | Ongoing cost | For |
|---|---|---|---|---|---|---|
| **0 — Private only** | GitHub-private repo — **no extra binary** | nothing at rest | **No** | none | none | Most vaults; content not especially sensitive |
| **1 — Content-encrypted** | **git-crypt** (symmetric key) on `content-paths` — **1 extra binary** | note **bodies + images** | **⚠ No** — titles/dates/entity names still visible | one-time/vault: install `git-crypt` + `init` + `.gitattributes` + back up key | **~none** — working tree stays plaintext for Obsidian + Claude; GitHub still browsable | Sensitive *contents*, non-sensitive *titles* |
| **2 — Fully opaque** | **git-remote-gcrypt** — **1 extra binary + GPG** | **everything** — contents + **filenames** + history | **Yes** | one-time/vault: install `git-remote-gcrypt` + `gnupg` + set `gcrypt::` remote + passphrase — *comparable to Tier 1, marginally heavier (GPG)* | **~none for daily editing** (working tree still plaintext); real cost is GitHub-side: **no web view / PR / diff / Actions** + heavier sync | Vaults where the *titles themselves* are the secret |

**Default = Tier 1.** It covers the common case at near-zero cost and stays transparent to the agent and Obsidian (they only ever see the decrypted working tree). Framework files stay plaintext, so `git pull upstream` remains clean.

**On cost (don't misread the table):** with **both** Tier 1 and Tier 2 you always **edit plaintext locally** — encryption happens *at rest* (in git objects / on push), so neither taxes day-to-day editing. Install/config is broadly comparable (each = one extra binary + a one-time per-vault step; Tier 2 is only marginally heavier because it also uses GPG). The genuine Tier-2 cost is **GitHub-side** — an opaque remote means no web view, PRs, diffs, or Actions on that repo — which is the natural consequence of full opacity, not daily friction. Weigh Tier 2 as *"do I need GitHub's web features on this vault?"*, not *"is it hard to use?"*

### How to choose (a threat-model question about YOUR data)
Are the **contents** sensitive, or are the **titles / dates / entity-names** sensitive too?
- Just contents → **Tier 1**.
- The titles themselves are the exposure → **Tier 2**.
- Neither → **Tier 0** (private is enough).

### ⚠ The Tier-1 filename limitation (read before choosing)
git-crypt encrypts file *contents*, not *filenames or directory structure*. In this system filenames are information-dense: CTN filenames are **verbatim source titles**, daily notes are **dated** (`2026-07-09.md`), generated pages are **entity/concept/project names**. So Tier 1 + a private repo can still leak *what you research, who you track, and when* from the directory listing alone. If that metadata is itself sensitive, you need **Tier 2**.

## Key management (Tier 1) — the critical operational rule

- The git-crypt **symmetric key IS your data.** It is generated **once** at `git-crypt init` and **cannot be regenerated**. Lose every copy — the operational one at `<vault>/.git/git-crypt/keys/default` **and** your backup — and the GitHub ciphertext is **permanently undecryptable**. No reset, no recovery.
- The key is **binary**, so back it up **base64-encoded** in a password manager (or an offline copy), separate from the repo. **A backup you have not test-restored does not count.**
- **→ Step-by-step, tested procedure (Bitwarden worked example): [`checklist.encryption-key-backup.md`](checklist.encryption-key-backup.md).** Export → password manager → the mandatory verify → restore, with the key never written to disk.
- The key must **NEVER be committed** (same class as the retired MCP-key incident). It is gitignored; the framework's `build-skeleton.sh` secret gate also scans for stray keys.
- Multi-machine / restore, no key file on disk: `git-crypt export-key /dev/stdout | base64 -w0` to back up → `printf %s '<base64>' | base64 -d | git-crypt unlock /dev/stdin` in each fresh clone.

## Operating rules

- **Enable at deploy time, before the first content commit.** Retrofitting onto a vault that already has plaintext content in its history requires a `git filter-repo` rewrite, or the old plaintext blobs live on GitHub forever. On a fresh vault it is trivial.
- **`.gitattributes` is vault-owned.** git-crypt is driven by a tracked `.gitattributes`; the framework must not ship one, so an upstream pull can never conflict with or silently disable a vault's encryption rules.
- **Concurrent edits corrupt encrypted content** — the single most dangerous failure mode; see **⚠ CRITICAL operating risk** at the top. Treat the vault as single-writer: pull before editing, push right after.
- **Open the vault in Obsidian only after the working tree is unlocked** (decrypted), or Obsidian sees ciphertext.

## Enable Tier 1 manually (until `enable-encryption.sh` ships)

> These are the interim manual steps; the future `enable-encryption.sh` will generate `.gitattributes` from `content-paths`, run `git-crypt init`, and gitignore the key automatically.

```bash
# per-machine, one-time: install the binary
sudo apt-get install -y git-crypt        # or: brew install git-crypt

# in a FRESH (no content yet) content vault:
git-crypt init
# encrypt the content paths; keep .gitattributes AND the empty .gitkeep placeholders unencrypted.
# (The .gitkeep line is REQUIRED: the content globs otherwise sweep in the framework's empty
#  placeholder files, which were committed before .gitattributes, and git-crypt warns on every push.)
printf '2_using_timeline/** filter=git-crypt diff=git-crypt\n3_generates_wiki/** filter=git-crypt diff=git-crypt\n.gitkeep !filter !diff\n.gitattributes !filter !diff\n' > .gitattributes
git add .gitattributes && git commit -m "enable content encryption (Tier 1, git-crypt)"

# back up the key — full verified procedure: checklist.encryption-key-backup.md
# quick form (base64 into your password manager; nothing left on disk):
git-crypt export-key /dev/stdout | base64 -w0; echo
```

Verify: a fresh clone *without* the key shows ciphertext under `2_using_timeline/` and `3_generates_wiki/`; after `git-crypt unlock ~/secure/<vault>.key` it shows plaintext.

## See also
- `checklist.new-wiki-project.md` §0.5 — the deploy-time tier decision.
- `DESIGN.content-vault-encryption.md` (dev, not shipped) — full rationale, the 5 hard problems, the open Tier-2 decision, and the spike/test plan.
- `spec.git-ops.md` — the clone/upstream model these rules sit within.
