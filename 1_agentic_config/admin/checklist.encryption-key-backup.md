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

- [ ] **A1.** In a terminal, from the vault root, send the key **straight to your clipboard** as one base64 line. **Do NOT print it and select it off the screen** — terminal/rendering can inject spaces or newlines, and a single stray character makes a **dead key that silently won't decrypt.** This writes nothing to disk and nothing to the screen:
  ```bash
  # Linux / X11:
  git-crypt export-key /dev/stdout | base64 -w0 | xclip -selection clipboard
  # Linux / Wayland:
  git-crypt export-key /dev/stdout | base64 -w0 | wl-copy
  # macOS:
  git-crypt export-key /dev/stdout | base64 | pbcopy
  ```
  Nothing prints — that is intentional. The key is now on your clipboard, uncorrupted.
- [ ] **A2.** Paste it directly into Bitwarden (next step) with Ctrl+V. *(If you have no clipboard tool and must eyeball it via `… | base64 -w0; echo`, know that hand-copying a base64 key off a display is the #1 cause of an unrecoverable dead backup — install `xclip`/`wl-clipboard` instead.)*
- [ ] **A3.** In **Bitwarden** → **New item → Secure Note**:
  - **Name:** `git-crypt key — <vault>` (e.g. `git-crypt key — akb-omd_AI-lightcone`).
  - Add a **custom field**, type **Hidden**, name `key-base64`, and paste the base64 into its value (Hidden keeps it masked).
  - In the **Notes** body, record — future-you needs these: the **GitHub repo URL**, the **vault name**, **today's date**, and paste the **restore command** from Section C.
  - **Save.**
- [ ] **A4.** One key per vault. If you have several encrypted vaults, repeat A1–A3 for each; never reuse one note for two vaults.

---

## Section B — VERIFY the backup NOW (non-negotiable anti-footgun)

> A backup you have never restored is not a backup. Prove it **while you still have the original**, so a bad copy is caught when it's harmless.

> **⚠ THE TWO-CLIPBOARD TRAP — read before you restore (this *will* bite you otherwise).** On Linux, **selecting text with the mouse** fills one clipboard (*primary*) while a password manager's **Copy button** fills another (*clipboard*). And to *run* a restore command you usually paste it — which **overwrites the clipboard with the command text, clobbering the key.** So do it in this exact order:
> 1. **Paste the restore command** into the terminal — but **do NOT press Enter yet.**
> 2. **Now click Copy** on the `key-base64` field in your password manager (this loads the key onto the clipboard).
> 3. **Press Enter.** The command reads the clipboard, which now holds the key.
>
> Symptoms of getting the order wrong: `base64: invalid input` or `not a valid git-crypt key file` — it means the clipboard held command text (or stale junk), not the key, when the command ran. Redo the three steps. *(Sanity check any time: `xclip -selection clipboard -o | tr -d '[:space:]' | wc -c` should be ~200, not tiny.)*

- [ ] **B1.** Clone the repo into a throwaway dir: `git clone <repo-url> /tmp/keytest`
- [ ] **B2.** Copy the `key-base64` value back **out** of Bitwarden.
- [ ] **B3.** Restore it **without writing the key to disk**, using the three-step clipboard order above (paste command → copy key in Bitwarden → Enter):
  ```bash
  xclip -selection clipboard -o | base64 -d | ( cd /tmp/keytest && git-crypt unlock /dev/stdin )
  ```
  *(Wayland: swap `xclip -selection clipboard -o` for `wl-paste`. No clipboard tool, or the trick won't cooperate? Paste the key straight into the command instead: `printf %s 'PASTE_BASE64_HERE' | base64 -d | ( cd /tmp/keytest && git-crypt unlock /dev/stdin )`.)*
- [ ] **B4.** Confirm a known file is now **plaintext** — open one in `2_using_timeline/`, or:
  ```bash
  grep -rl . /tmp/keytest/2_using_timeline | head
  ```
- [ ] **B5.** **PASS = readable plaintext.** If it's still gibberish, your stored key is wrong — **redo Section A** now. Then remove `/tmp/keytest` (delete it in your file manager if a guard blocks `rm`).

---

## Section C — Restore (when you actually need it: new machine, lost vault, dead disk)

- [ ] **C1.** Clone the repo: `git clone <repo-url> <vault>`
- [ ] **C2.** Get the `key-base64` from Bitwarden.
- [ ] **C3.** Unlock (no key file on disk), using the **three-step clipboard order** from Section B (paste command → copy key in Bitwarden → Enter):
  ```bash
  xclip -selection clipboard -o | base64 -d | ( cd <vault> && git-crypt unlock /dev/stdin )
  ```
  *(Fallback — paste the key into the command directly: `printf %s 'PASTE_BASE64_HERE' | base64 -d | ( cd <vault> && git-crypt unlock /dev/stdin )`.)*
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
