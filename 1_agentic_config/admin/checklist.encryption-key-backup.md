---
title: Encryption Key — Back Up & Restore (step-by-step)
description: Foolproof, tested checklist for backing up and restoring a Tier-1 (git-crypt) vault key via a password manager. Worked example uses Bitwarden. This is the single most unrecoverable operation in the system — do it carefully and VERIFY.
---

# Back Up & Restore Your Encryption Key (Tier 1 / git-crypt)

> **⛔ READ THIS FIRST — why this checklist exists.** The git-crypt key **IS your data.** Lose every copy and the content you pushed to GitHub becomes a permanently undecryptable blob — **no reset, no recovery, no support, ever.** This is the one operation where a fumble is unrecoverable. So: do it slowly, and **prove your backup works (Section B) before you rely on it.**

## What you are backing up

- Each encrypted vault has **its own** symmetric key. Back up **one key per vault**, named for that vault.
- The **operational copy** lives at `<vault>/.git/git-crypt/keys/default` — a **binary** file, inside `.git`, never committed, never in the working tree. You do **not** touch it directly.
- This checklist stores a **portable copy** of that key in your password manager. Because the key is binary (not text), you store it **base64-encoded**.

---

## Section A — Back up the key (do ONCE, right after enabling encryption)

- [ ] **A1.** In a terminal, from the vault root, print the key as one base64 line (writes nothing to disk):
  ```bash
  git-crypt export-key /dev/stdout | base64 -w0; echo
  ```
  It prints **one long line** (~200 characters for a fresh key). *(macOS: `base64` wraps differently — use `git-crypt export-key /dev/stdout | base64 | tr -d '\n'; echo`.)*
- [ ] **A2.** Select and copy the **entire** line — no leading/trailing spaces, no line breaks. (A truncated key is a dead key.)
- [ ] **A3.** In **Bitwarden** → **New item → Secure Note**:
  - **Name:** `git-crypt key — <vault>` (e.g. `git-crypt key — akb-omd_AI-lightcone`).
  - Add a **custom field**, type **Hidden**, name `key-base64`, and paste the base64 into its value (Hidden keeps it masked).
  - In the **Notes** body, record — future-you needs these: the **GitHub repo URL**, the **vault name**, **today's date**, and paste the **restore command** from Section C.
  - **Save.**
- [ ] **A4.** One key per vault. If you have several encrypted vaults, repeat A1–A3 for each; never reuse one note for two vaults.

---

## Section B — VERIFY the backup NOW (non-negotiable anti-footgun)

> A backup you have never restored is not a backup. Prove it **while you still have the original**, so a bad copy is caught when it's harmless.

- [ ] **B1.** Clone the repo into a throwaway dir: `git clone <repo-url> /tmp/keytest`
- [ ] **B2.** Copy the `key-base64` value back **out** of Bitwarden.
- [ ] **B3.** Restore it **without writing the key to disk** (paste your base64 where shown):
  ```bash
  printf %s 'PASTE_BASE64_HERE' | base64 -d | ( cd /tmp/keytest && git-crypt unlock /dev/stdin )
  ```
- [ ] **B4.** Confirm a known file is now **plaintext** — open one in `2_using_timeline/`, or:
  ```bash
  grep -rl . /tmp/keytest/2_using_timeline | head
  ```
- [ ] **B5.** **PASS = readable plaintext.** If it's still gibberish, your stored key is wrong — **redo Section A** now. Then remove `/tmp/keytest` (delete it in your file manager if a guard blocks `rm`).

---

## Section C — Restore (when you actually need it: new machine, lost vault, dead disk)

- [ ] **C1.** Clone the repo: `git clone <repo-url> <vault>`
- [ ] **C2.** Get the `key-base64` from Bitwarden.
- [ ] **C3.** Unlock (no key file on disk):
  ```bash
  printf %s 'PASTE_BASE64_HERE' | base64 -d | ( cd <vault> && git-crypt unlock /dev/stdin )
  ```
- [ ] **C4.** The working tree is now plaintext. Open in Obsidian normally.

---

## Appendix — temp-file method (fallback if the pipe method fails)

Some environments choke on `/dev/stdin`. Then decode to a real file, unlock, and **securely delete it**:
```bash
printf %s 'PASTE_BASE64_HERE' | base64 -d > /tmp/k.key
( cd <vault> && git-crypt unlock /tmp/k.key )
shred -u /tmp/k.key          # securely erase — never leave a plaintext key lying around
```

## The rules that save you

- **Verify (Section B) or it doesn't count.** Every backup, every time.
- **One key per vault**, named for the vault.
- The key is **never committed** and **never in the working tree** — only in your password manager and in `.git/git-crypt/keys/`.
- If you ever rotate the key, **re-run Section A immediately** (the old backup no longer decrypts new commits).
- **Tier 2 (git-remote-gcrypt)** uses a passphrase via `gpg-agent` instead of a key file — different backup story; this checklist is Tier 1 only.

**See also:** `spec.content-encryption.md` (the tier model + the ⚠ concurrent-edit risk) · `checklist.new-wiki-project.md` §0.5 (the deploy-time tier decision).
