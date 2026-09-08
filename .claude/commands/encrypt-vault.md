Enable optional at-rest **encryption on THIS content vault** — the step that follows
`setup.sh`. Orchestrates `1_agentic_config/scripts/enable-encryption.sh`, which is the
single source of truth for the mechanics; **do not restate its steps or the tier tables
here** (that duplication is what lets a command drift from its spec). Read
[[spec.content-encryption.md]] for the model and `--help` on the script for the flags.

`$ARGUMENTS` may name the tier (`1`, `2`, `tier 1`, `tier 2`). If absent, help the
curator choose one first (see below).

Steps:

1. **Refuse on the framework repo.** Encryption is for **content vaults only** — never the
   shared framework (`agentic-KB_OMD`). If `git remote -v` shows `origin` pointing at the
   framework, or a `.githooks` content-guard is active (gateway role), **stop** and say so.

2. **Confirm the timing rule.** Encryption must be enabled **before the first content
   commit** (the script enforces this and will refuse otherwise). If the vault already
   holds real content, stop and surface that — retrofitting needs a history rewrite.

3. **Help choose a tier** (only if `$ARGUMENTS` didn't specify): ask the curator the
   threat-model question from `spec.content-encryption.md` "How to choose" — are just the
   *contents* sensitive (**Tier 1**, git-crypt), or the *titles/filenames* too (**Tier 2**,
   git-remote-gcrypt)? Neither → they don't need this command (Tier 0). Don't re-derive the
   trade-offs; cite the spec.

4. **Hand the run to the curator — do not drive the destructive/secret steps yourself.**
   The script is human-run for good reason: typed confirmations gate an irreversible repo
   reset (Tier 2), the encrypted push pops a **modal pinentry** you cannot fill, and key
   backup is secret custody. Ask the curator to run it via a `! ...` line so its output
   lands in the session:

   ```
   ! ./1_agentic_config/scripts/enable-encryption.sh --tier <N>
   ```

5. **Guide the tier-specific human steps** the script prints, using the established
   pinentry pattern (as when backing up gcrypt vaults):
   - **Tier 2:** remind them to copy the GPG passphrase to the clipboard *first*, then run
     `git push origin main` (modal pinentry); if no dialog appears, that's gpg-agent's
     cache — never trust silence. **If the first push timed out** at the modal, the retry
     may abort with `…repository ID is set. Aborting.` — clear the stale id with
     `git config --unset remote.origin.gcrypt-id`, then push again.
   - **Tier 1:** walk them through the **key backup** (base64 → password manager →
     test-restore, per `encryption.checklist.git-crypt.key-backup.md`) and the plain
     `git push origin main`.

6. **Verify and report.** Have them run `enable-encryption.sh --tier <N> --verify` and
   report PASS/FAIL. For Tier 2, a PASS means the plain remote is opaque and the gcrypt
   clone round-trips; for Tier 1, that `wiki.index.md` and the content plane are encrypted.

---

**Why this is a command:** it turns "the optional encryption step after deploy" into one
guided flow, and keeps the dangerous parts (repo reset, pinentry, key custody) firmly in
the curator's hands while the agent handles derivation, sequencing, and verification.
Pairs with `setup.sh`: **deploy → optionally `/encrypt-vault` → first ingest.** Full
rationale and the three-tier model: [[spec.content-encryption.md]].
