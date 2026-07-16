---
title: Encryption Secret — Back Up & Restore (Tier 2 / git-remote-gcrypt + GPG)
description: Placeholder for the Tier-2 (git-remote-gcrypt) secret-custody checklist — to be written from the Tier-2 spike results. Parallels encryption.checklist.git-crypt.key-backup.md.
---

# Back Up & Restore Your Encryption Secret (Tier 2 / git-remote-gcrypt + GPG)

> **⛔ READ THIS FIRST — the secret *IS* your data, and losing it is UNRECOVERABLE.** It is natural to think of a GPG keypair like an SSH keypair — same `~/.gnupg` ↔ `~/.ssh` shape, same agent, same passphrase-protected private key. **Do not carry over SSH habits.** An SSH key only **authenticates** you to GitHub: lose it and you generate a new pair, re-upload the public half, and **no data is lost**. Tier 2's GPG secret (the **passphrase** in symmetric mode, or the **secret key *and* its passphrase** in public-key mode) is different in kind — it **decrypts the repository itself.** Lose every copy and the content you pushed to GitHub becomes a **permanently undecryptable blob — no reset, no recovery, no support, ever.** So back it up carefully, store **every** required secret (in public-key mode that is *two* things: the key **and** the passphrase), and **prove the backup restores before you rely on it.** This is the single most unrecoverable operation in the system.

**TBD (procedure), based on testing results.**

This is the Tier-2 counterpart to [[encryption.checklist.git-crypt.key-backup|the git-crypt key-backup checklist]]. Tier 2 secures the repo with a **GPG passphrase (or keypair) held by `gpg-agent`** rather than a git-crypt key file, so the backup/restore story differs. The step-by-step procedure will be filled in once the Tier-2 spike (`SPIKE.tier2-gcrypt.throwaway2`) validates the exact commands.

---

## Default mode for these vaults: **symmetric (passphrase)**

This vault family uses **symmetric / passphrase mode** — `git-remote-gcrypt` with `gcrypt-participants` left **unset**. There is **no keypair**; a single **passphrase** encrypts the whole repo, so you back up **one secret** (the passphrase), exactly mirroring the Tier-1 single-secret model. It is the simplest path with the fewest breakable parts — the right default for a solo personal vault. The full step-by-step lands here once the Tier-2 spike validates the exact commands.

---

## Appendix — Alternative: public-key (multi-recipient) mode · *optional, NOT the default*

> Use this **only** if more than one identity/person must decrypt the vault — sharing with a collaborator, or unlocking from several of your own GPG identities. For a solo vault, stay with symmetric mode above. **These commands are the planned shape, not yet spike-validated — verify against the installed `git-remote-gcrypt` before relying on them.**

Public-key mode encrypts the repo **to one or more GPG keys**; each holder decrypts with their own secret key. Custody is **two fatal secrets**: the secret key **and** its passphrase — lose either and you lose access.

**1. Generate the key — and set it to NEVER EXPIRE:**
```bash
gpg --quick-generate-key "Vault Name <admin@vyzed.net>" default default never
```
> ⛔ **Do NOT accept the common one-year (`1y`) expiry default that tutorials use.** This is a **data-at-rest decryption key**, not a signing/identity key. An expired key can still decrypt *old* data, but it **blocks new encrypted pushes** and throws warnings until you extend it — pure friction for an archive you must open years from now. **Explicitly set it to `never`** (equivalently `0`). If a key was already made with an expiry, remove it: `gpg --edit-key <fingerprint>` → `expire` → `0` → `save`.

**2. Point origin at the gcrypt remote and list participant key(s) by fingerprint:**
```bash
git remote set-url origin gcrypt::https://github.com/<you>/<vault>.git
git config remote.origin.gcrypt-participants "<YOUR_KEY_FINGERPRINT>"
# add more fingerprints, space-separated, to grant others decrypt access
git push origin main
```

**3. Back up BOTH secrets to your password manager:**
```bash
gpg --export-secret-keys --armor <FINGERPRINT>   # store this armored block
# AND, separately, store the passphrase that protects it
```
Verify the backup by **fingerprint** (`gpg --fingerprint <FINGERPRINT>`), **never by eyeballing** the armored block — every armored key looks identical at head and tail. Prove restore in a **clean `GNUPGHOME`** (so `gpg-agent` can't hand you a false pass) before relying on it.
