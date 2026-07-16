---
title: Encryption Secret — Back Up & Restore (Tier 2 / git-remote-gcrypt + GPG)
description: Placeholder for the Tier-2 (git-remote-gcrypt) secret-custody checklist — to be written from the Tier-2 spike results. Parallels encryption.checklist.git-crypt.key-backup.md.
---

# Back Up & Restore Your Encryption Secret (Tier 2 / git-remote-gcrypt + GPG)

**TBD, based on testing results.**

This is the Tier-2 counterpart to [[encryption.checklist.git-crypt.key-backup|the git-crypt key-backup checklist]]. Tier 2 secures the repo with a **GPG passphrase (or keypair) held by `gpg-agent`** rather than a git-crypt key file, so the backup/restore story differs. The step-by-step procedure will be filled in once the Tier-2 spike (`SPIKE.tier2-gcrypt.throwaway2`) validates the exact commands.
