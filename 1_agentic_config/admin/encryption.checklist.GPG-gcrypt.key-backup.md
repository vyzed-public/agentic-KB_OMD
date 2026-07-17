---
title: Encryption Secret — Back Up & Restore (Tier 2 / git-remote-gcrypt + GPG)
description: Placeholder for the Tier-2 (git-remote-gcrypt) secret-custody checklist — to be written from the Tier-2 spike results. Parallels encryption.checklist.git-crypt.key-backup.md.
---

# Back Up & Restore Your Encryption Secret (Tier 2 / git-remote-gcrypt + GPG)

> **⛔ READ THIS FIRST — the secret *IS* your data, and losing it is UNRECOVERABLE.** It is natural to think of a GPG keypair like an SSH keypair — same `~/.gnupg` ↔ `~/.ssh` shape, same agent, same passphrase-protected private key. **Do not carry over SSH habits.** An SSH key only **authenticates** you to GitHub: lose it and you generate a new pair, re-upload the public half, and **no data is lost**. Tier 2's GPG secret — your **secret key *and* the passphrase** that protects it (two things) — is different in kind: it **decrypts the repository itself.** Lose every copy and the content you pushed to GitHub becomes a **permanently undecryptable blob — no reset, no recovery, no support, ever.** So back it up carefully, store **both** required secrets (the key **and** its passphrase — they are useless apart), and **prove the backup restores before you rely on it.** This is the single most unrecoverable operation in the system.

This is the Tier-2 counterpart to [[encryption.checklist.git-crypt.key-backup|the git-crypt key-backup checklist]]. The procedure below was validated by the Tier-2 spike (run-1, 2026-07-16).

---

## How Tier 2 works — and why there are TWO secrets

**git-remote-gcrypt always encrypts to a GPG key — there is no keyless or passphrase-only "symmetric" mode.** (The installed manpage is explicit: *"You need a personal GPG key."*) For a **solo vault** you leave `gcrypt-participants` **unset** — equivalently, set it to the literal `simple` — which means *"encrypt to your own default key."* Single-recipient: only you can decrypt. To share the vault with others, list their keys too (see *Multi-recipient* below).

Either way, your custody is **two secrets that are useless apart**:
1. your **GPG secret key** (the key material), and
2. the **passphrase** that protects it.

Lose either and the repo is permanently undecryptable. Back up **both** (below) and **verify the restore**.

---

## Back up & restore your key & passphrase (validated — Tier-2 spike run-1, 2026-07-16)

> This procedure was proven end-to-end: key generated → backed up → the vault destroyed → recovered from the **password manager alone in a clean keyring**. Follow it exactly.

**1. Generate the key — and set it to NEVER EXPIRE:**
```bash
gpg --quick-generate-key "Vault Name <admin@vyzed.net>" default default never
```
> ⛔ **Do NOT accept the common one-year (`1y`) expiry default that tutorials use.** This is a **data-at-rest decryption key**, not a signing/identity key. An expired key can still decrypt *old* data, but it **blocks new encrypted pushes** and throws warnings until you extend it — pure friction for an archive you must open years from now. **Explicitly set it to `never`** (equivalently `0`). If a key was already made with an expiry, remove it: `gpg --edit-key <fingerprint>` → `expire` → `0` → `save`.

**2. Point origin at the gcrypt remote and push (solo = leave participants UNSET):**
```bash
git remote set-url origin gcrypt::https://github.com/<you>/<vault>.git
# Solo vault: do NOT set gcrypt-participants — unset means "encrypt to your own key".
git push origin main   # first push builds the encrypted remote; you'll be prompted for your key passphrase
```
> **⚠ First push is implicitly a `--force`** (a known git-remote-gcrypt behaviour). Harmless for a solo vault; for a shared one set `git config remote.origin.gcrypt-require-explicit-force-push true`.
> **Multi-recipient (optional):** to let others decrypt, before pushing run `git config remote.origin.gcrypt-participants "<YOUR_FP> <THEIR_FP> …"` — each holder then decrypts with their own secret key.
> **After a fresh clone the working tree is EMPTY** (`warning: remote HEAD refers to nonexistent ref, unable to checkout`) because gcrypt's remote HEAD points at `master`. Fix: `git checkout main`.

**3. Back up BOTH secrets to your password manager — the key MUST be base64-encoded:**
```bash
# 3a. Key material — base64-encode it (this is REQUIRED, not optional; see the ⛔ box):
gpg --export-secret-keys <FINGERPRINT> | base64 -w0
#     → one long single line. Store THIS in Bitwarden's Notes body.
# 3b. Passphrase — store separately (a Hidden custom field is fine).
```
Restore later with:
```bash
# copy the base64 string out of your manager, then:
base64 -d | gpg --import          # or: pbpaste / xclip -o | base64 -d | gpg --import
```

> ⛔ **base64-encode the key — do NOT store the raw `gpg --export-secret-keys --armor` block. This is a TESTED finding: storing raw armor silently CORRUPTS the backup.** Password-manager fields are HTML form controls (Bitwarden is an Electron/Chromium app). A **single-line field strips the newlines** out of a multi-line armored key, so it comes back as one space-joined blob and `gpg --import` rejects it — *"no valid OpenPGP data found."* The result is a **dead backup that looks fine right up until the day you need it and can't decrypt anything.** `base64 -w0` output is a single line with **no newlines or whitespace**, so there is nothing left for any field to mangle — it survives the round-trip that armor does not.

**Verify the backup — do NOT skip (this is the step that catches the corruption above):**
- **Fingerprint-match** the restored key: `gpg --fingerprint <FINGERPRINT>` — compare to the original. Never eyeball the key blob (they all look alike).
- **Prove a full restore in a clean `GNUPGHOME`** (`export GNUPGHOME=$(mktemp -d)`) so a cached `gpg-agent` passphrase can't fake a pass: `base64 -d | gpg --import` the stored copy, then confirm the fingerprint and (ideally) an actual `git clone gcrypt::…` decrypt.

> **📋 Storing the secrets in your password manager — practical gotchas (Bitwarden, tested):**
> - **The base64 key is too big for a custom field** (~5 KB > Bitwarden's **5000-char custom-field cap** — you'll get *"The field Value exceeds the maximum encrypted value length of 5000 characters."*). Put the base64 string in the note's main **Notes body** (~10,000-char limit). A file **attachment** (the `.asc`/base64 as a file) also preserves it exactly, but needs Bitwarden premium.
> - **Passphrase → a *Hidden* custom field.** "Hidden" masks only the *value*; the field **label stays visible** and keeps a **copy button**, so you can see it's there and copy it without revealing it. Masked is the correct treatment for a secret.
> - **Both secrets are required and useless apart** — the passphrase unlocks nothing without the key material, and vice-versa. For defense-in-depth you may split them into **two separate notes**; one note with the passphrase field + base64-key-in-Notes is also fine.
> - **Modal pinentry:** the passphrase dialog grabs focus, so you can't switch to your manager once it's up. **Copy the passphrase to your clipboard BEFORE running any gpg step**, then paste it into the dialog.
