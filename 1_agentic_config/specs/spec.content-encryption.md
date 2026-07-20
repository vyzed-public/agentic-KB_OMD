---
title: Content-Vault Encryption
created: 2026-07-09
updated: 2026-07-19
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
| **2 — Fully opaque** | **git-remote-gcrypt** — **1 extra binary + GPG** | **everything** — contents + **filenames** + history | **Yes** | one-time/vault: install `git-remote-gcrypt` + `gnupg`, **generate a never-expiring GPG key**, set the `gcrypt::` remote, **back up key *and* passphrase** — *marginally heavier than Tier 1 (the GPG key step)* | **~none for daily editing** (working tree still plaintext); real cost is GitHub-side: **no web view / PR / diff / Actions** + heavier sync | Vaults where the *titles themselves* are the secret |

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
- **→ Step-by-step, tested procedure (Bitwarden worked example): [`encryption.checklist.git-crypt.key-backup.md`](encryption.checklist.git-crypt.key-backup.md).** Export → password manager → the mandatory verify → restore, with the key never written to disk.
- The key must **NEVER be committed** (same class as the retired MCP-key incident). It is gitignored; the framework's `build-skeleton.sh` secret gate also scans for stray keys.
- Multi-machine / restore, no key file on disk: `git-crypt export-key /dev/stdout | base64 -w0` to back up → `printf %s '<base64>' | base64 -d | git-crypt unlock /dev/stdin` in each fresh clone.

## Key management (Tier 2) — TWO secrets, and no symmetric shortcut

_Validated by the Tier-2 spike (run-1, 2026-07-16)._

- **git-remote-gcrypt always encrypts to a GPG key — there is NO keyless / passphrase-only "symmetric" mode.** The manpage is explicit: *"You need a personal GPG key."* Leaving `gcrypt-participants` **unset** — equivalently the literal value `simple` — means *"encrypt to your own default key"* (single-recipient; the solo-vault default). Setting it to a space-separated list of **fingerprints** grants multi-recipient access.
- **Custody is TWO secrets, useless apart: the GPG secret key AND its passphrase.** Lose either and the GitHub blob is **permanently undecryptable**. (Do not reason about it like an SSH key — an SSH key only authenticates and is freely regenerable; this one *decrypts your data*.)
- **Back the key up BASE64-encoded** — `gpg --export-secret-keys <FPR> | base64 -w0` — **not** as a raw `--armor` block. Password-manager fields are HTML form controls (Electron/Chromium); a single-line field **strips the newlines** out of armor, silently producing a **dead backup** that `gpg --import` later rejects (*"no valid OpenPGP data found"*). base64 `-w0` is one line with nothing to mangle. **Tested — this exact corruption bit us in the spike and was caught only by the verify step.**
- **Generate with no expiry** (`gpg --quick-generate-key "<name> <email>" default default never`) — this is a *data-at-rest* key; an expired key still decrypts old data but blocks new pushes and throws warnings.
- **→ Step-by-step, tested procedure: [`encryption.checklist.GPG-gcrypt.key-backup.md`](encryption.checklist.GPG-gcrypt.key-backup.md).** Back up → the mandatory fingerprint verify → restore in a clean `GNUPGHOME`.
- **Operational gotchas:** the first gcrypt push is implicitly a `--force` (set `gcrypt-require-explicit-force-push` on shared vaults); a **fresh gcrypt clone leaves an EMPTY working tree** (`remote HEAD refers to nonexistent ref`) until you run **`git checkout main`**; pinentry is **modal**, so copy the passphrase to your clipboard *before* running any gpg step.

## Operating rules

- **Enable at deploy time, before the first content commit.** Retrofitting onto a vault that already has plaintext content in its history requires a `git filter-repo` rewrite, or the old plaintext blobs live on GitHub forever. On a fresh vault it is trivial.
- **`.gitattributes` is vault-owned.** git-crypt is driven by a tracked `.gitattributes`; the framework must not ship one, so an upstream pull can never conflict with or silently disable a vault's encryption rules.
- **Concurrent edits corrupt encrypted content** — the single most dangerous failure mode; see **⚠ CRITICAL operating risk** at the top. Treat the vault as single-writer: pull before editing, push right after.
- **Open the vault in Obsidian only after the working tree is unlocked** (decrypted), or Obsidian sees ciphertext.

## Enable Tier 1 manually (until `enable-encryption.sh` ships)

> These are the interim manual steps; the future `enable-encryption.sh` will generate `.gitattributes` from `content-paths`, run `git-crypt init`, **re-encrypt any pre-existing content-path files**, and gitignore the key automatically.

```bash
# per-machine, one-time: install the binary
sudo apt-get install -y git-crypt        # or: brew install git-crypt

# in a content vault with NO real content yet (before the first content commit):
git-crypt init

# Write .gitattributes: encrypt the content paths, but keep TWO classes of file plaintext —
#   - .gitattributes itself (git-crypt has to read it), and
#   - the empty .gitkeep placeholders the framework ships in the content dirs (they hold nothing,
#     and being committed before .gitattributes they would otherwise make git-crypt warn on every push).
printf '2_using_timeline/** filter=git-crypt diff=git-crypt\n3_generates_wiki/** filter=git-crypt diff=git-crypt\n.gitkeep !filter !diff\n.gitattributes !filter !diff\n' > .gitattributes
git add .gitattributes

# ⚠ RE-ENCRYPT PRE-EXISTING CONTENT-PATH FILES — do NOT skip this step.
# git-crypt only encrypts files as they are staged AFTER .gitattributes exists; it does NOT
# retroactively encrypt what was already committed plaintext. The framework ships one such file
# inside a content path: 3_generates_wiki/wiki.index.md (the wiki catalog — it lists every
# source/concept/entity page name, so it SHOULD be encrypted, unlike the exempted .gitkeep).
# Writing .gitattributes alone leaves it PLAINTEXT on the remote. Re-stage every should-be-encrypted
# file through git-crypt's clean filter:
git-crypt status -f          # re-stages wiki.index.md (and any other pre-existing content-path file)

git commit -m "enable content encryption (Tier 1, git-crypt)"

# CONFIRM before pushing — wiki.index.md must be listed as *encrypted*, not "not encrypted":
git-crypt status 3_generates_wiki/wiki.index.md

# back up the key — full verified procedure: encryption.checklist.git-crypt.key-backup.md
# quick form (base64 into your password manager; nothing left on disk):
git-crypt export-key /dev/stdout | base64 -w0; echo
```

Verify end-to-end: a fresh clone *without* the key shows ciphertext under `2_using_timeline/` and `3_generates_wiki/` — **including `wiki.index.md`** (grep it for a known page name; it must not appear); after `git-crypt unlock <key>` it shows plaintext. **If `wiki.index.md` is still readable in a keyless clone, the `git-crypt status -f` re-encryption step was missed** — the single easiest Tier-1 mistake to make.

## Enable Tier 2 manually (until `enable-encryption.sh` ships)

> Tier 2 wraps the **remote** in git-remote-gcrypt: the whole push becomes one opaque blob (contents **+ filenames + history**). No `.gitattributes`, no per-file handling — encryption is wholesale at push time. It **requires a GPG key** (Tier 2 has no keyless/symmetric mode — see "Key management (Tier 2)" above); generate + back it up per `encryption.checklist.GPG-gcrypt.key-backup.md`, or reuse an existing solo key.

**⚠ STEP ZERO — the remote MUST be free of plaintext history, or Tier 2 silently fails.** gcrypt stores its encrypted data under the remote's **`master`** ref (its internal convention) and does **not** touch any pre-existing branch. Our own deploy flow (`checklist.new-wiki-project.md`) pushes the framework scaffold **plaintext** at setup — so a *deployed* vault's GitHub repo already has a plaintext `main`. Enable gcrypt on top and that plaintext `main` **remains**, `HEAD` still points at it, and a plain `git clone` serves the **plaintext tree — filenames and all** — defeating the entire point of Tier 2. **Delete and recreate the GitHub repo before the first gcrypt push:**
```bash
gh repo delete <owner>/<REPO> --confirm         # gh 2.4.0 → --confirm (NOT --yes)
gh repo create <owner>/<REPO> --private
git config --unset remote.origin.gcrypt-id      # only if a prior gcrypt push already set it
```
*(Here the leaked plaintext was only framework files, but for a vault whose filenames are the secret this step is mandatory. TESTED: skipping it left a plaintext `main` beside gcrypt's `master` on a real vault; the plain-clone opacity check caught it.)*

```bash
# per-machine, one-time: install the binaries
sudo apt-get install -y git-remote-gcrypt gnupg

# in a content vault with NO real content yet AND a plaintext-free remote (Step Zero):
# point origin at the gcrypt remote. Solo vault → leave gcrypt-participants UNSET
# (unset ≡ "simple" ≡ encrypt to your own default key; single-recipient).
git remote set-url origin gcrypt::https://github.com/<owner>/<REPO>.git

# first (encrypted) push — pops a MODAL pinentry for the GPG passphrase
git push origin main
```
PASS on the push: `Setting up new repository`, `Remote ID is …`, `Encrypting to: --throw-keyids --default-recipient-self`, `[new branch] main` (plus an implicit-`--force` note).

Verify (BOTH must pass):
```bash
D=$(mktemp -d)
# opacity — a PLAIN clone must be only opaque hash-named blobs (no filenames, no plaintext):
git clone https://github.com/<owner>/<REPO>.git "$D/raw"
find "$D/raw" -not -path '*/.git/*' -type f          # → 2 opaque blobs (manifest + pack), nothing else
git ls-remote https://github.com/<owner>/<REPO>.git  # → ONLY refs/heads/master (NO plaintext main)
# round-trip — a gcrypt clone must decrypt back to plaintext:
git clone gcrypt::https://github.com/<owner>/<REPO>.git "$D/unlocked"
git -C "$D/unlocked" checkout main                    # REQUIRED — fresh gcrypt clone lands on an empty tree
```

**Gotchas** (all bit us for real):
- **Modal pinentry** — copy the passphrase to your clipboard BEFORE running the push/clone (it grabs focus). An agent driving the command cannot see or fill the dialog; the human must.
- **Fresh gcrypt clone = empty working tree** (`remote HEAD refers to nonexistent ref`) → always `git checkout main`.
- **First gcrypt push is implicitly `--force`** → for a shared vault set `git config remote.origin.gcrypt-require-explicit-force-push true`.

## See also
- `checklist.new-wiki-project.md` §0.5 — the deploy-time tier decision.
- `DESIGN.content-vault-encryption.md` (dev, not shipped) — full rationale, the 5 hard problems, the open Tier-2 decision, and the spike/test plan.
- `spec.git-ops.md` — the clone/upstream model these rules sit within.
