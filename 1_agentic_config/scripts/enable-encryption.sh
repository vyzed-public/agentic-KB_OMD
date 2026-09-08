#!/usr/bin/env bash
# enable-encryption.sh — enable at-rest encryption on a CONTENT vault.
# ONE script for both tiers; the optional encryption step that follows setup.sh.
#
#   ./1_agentic_config/scripts/enable-encryption.sh --tier 1            # git-crypt (contents)
#   ./1_agentic_config/scripts/enable-encryption.sh --tier 2 [--fpr X]  # git-remote-gcrypt (everything)
#   ./1_agentic_config/scripts/enable-encryption.sh --tier 1 --verify
#   ./1_agentic_config/scripts/enable-encryption.sh --tier 2 --verify
#
# TIER 1 (git-crypt): encrypts note BODIES + images in place (filenames stay visible).
# TIER 2 (git-remote-gcrypt): wraps the whole remote as ONE opaque blob — contents
#         + filenames + history.
# Generalizes the validated manual processes (dev issue #5 + spec.content-encryption.md
# "Enable Tier 1/2 manually").
#
# Run it FROM INSIDE the vault you want to encrypt: everything is derived from there —
# owner/repo from `origin`, the signing key from `gpg` — so you supply no identifiers,
# only confirmation. It STARTs by confirming which local vault you are in (Tier 2 also
# shows/confirms the origin remote state), then proceeds.
#
# HUMAN-RUN by design. It never performs the secret-custody or modal-pinentry steps
# blind: destructive/irreversible actions are gated by typed confirmations, and the
# encrypted push + key backup are handed to you. The /encrypt-vault skill orchestrates.
set -euo pipefail

TIER=""
FPR=""
MODE=enable
while [ $# -gt 0 ]; do
  case "$1" in
    --tier)    TIER="${2:-}"; shift 2;;
    --fpr)     FPR="${2:-}"; shift 2;;
    --verify)  MODE=verify; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "enable-encryption.sh: unknown argument '$1'" >&2; exit 2;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

case "$TIER" in 1|2) ;; *) die "pass --tier 1 (git-crypt) or --tier 2 (git-remote-gcrypt).";; esac

ROOT=$(git rev-parse --show-toplevel) || die "not inside a git repository."
cd "$ROOT"

# --- derive owner/repo from origin, best-effort (Tier 2 requires it) ---
O=""; R=""
if ORIGIN_URL=$(git remote get-url origin 2>/dev/null); then
  plain_url=${ORIGIN_URL#gcrypt::}; plain_url=${plain_url%.git}
  [[ $plain_url =~ github\.com[:/]+([^/]+)/([^/]+)$ ]] && { O=${BASH_REMATCH[1]}; R=${BASH_REMATCH[2]}; }
else
  ORIGIN_URL=""
fi

# The content plane encrypted by Tier 1 — the VALIDATED globs (spike-proven). Broader
# than content-paths on purpose: it must cover 3_generates_wiki/wiki.index.md (the
# catalog), which content-paths does not list. Keep .gitattributes + .gitkeep plaintext.
GITATTRIBUTES_BODY='2_using_timeline/** filter=git-crypt diff=git-crypt
3_generates_wiki/** filter=git-crypt diff=git-crypt
.gitkeep !filter !diff
.gitattributes !filter !diff'

# --- common: refuse if real content is already committed (spec timing rule) ---
timing_guard() {
  local cp="1_agentic_config/scripts/content-paths"
  [ -f "$cp" ] || return 0
  local patterns offending="" f p
  mapfile -t patterns < <(grep -vE '^\s*(#|$)' "$cp")
  while IFS= read -r f; do
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    for p in "${patterns[@]}"; do
      # shellcheck disable=SC2053
      if [[ $f == $p ]]; then offending+="  $f"$'\n'; break; fi
    done
  done < <(git ls-files)
  if [ -n "$offending" ]; then
    echo "ERROR: real content is already committed in this vault:" >&2
    printf '%s' "$offending" >&2
    echo "Encryption must be enabled BEFORE the first content commit (spec.content-encryption.md" >&2
    echo "timing rule) — otherwise plaintext blobs persist in history. Enable on a fresh vault," >&2
    echo "or rewrite history with git-filter-repo first." >&2
    exit 1
  fi
}

# --- common: confirm which local vault we're operating on ---
confirm_local_vault() {
  local vault_dir; vault_dir=$(basename "$ROOT")
  echo "== Enable Tier $TIER encryption =="
  echo "Local vault directory : $vault_dir"
  echo "Full path             : $ROOT"
  printf "Confirm this is the vault to encrypt by typing its directory name '%s': " "$vault_dir"
  local ldir; read -r ldir || die "no input on stdin — run this in your terminal."
  [ "$ldir" = "$vault_dir" ] || die "'$ldir' != '$vault_dir' — aborted, nothing changed."
}

# =============================================================================
# VERIFY
# =============================================================================
if [ "$MODE" = verify ]; then
  if [ "$TIER" = 1 ]; then
    command -v git-crypt >/dev/null 2>&1 || die "git-crypt not installed."
    echo "== Verify Tier 1 (git-crypt) =="
    [ -e .git/git-crypt/keys/default ] || die "git-crypt is not initialized in this repo."
    if git-crypt status -e 2>/dev/null | grep -q '3_generates_wiki/wiki.index.md'; then
      echo "  PASS: wiki.index.md is encrypted"
    else
      echo "  FAIL: wiki.index.md is NOT encrypted — the 'git-crypt status -f' re-encrypt step was missed"
      exit 1
    fi
    if unenc=$(git-crypt status -u 2>/dev/null | grep -E '^\s*(2_using_timeline/|3_generates_wiki/)' | grep -v '\.gitkeep'); then
      [ -n "$unenc" ] && { echo "  FAIL: content-plane files left unencrypted:"; printf '%s\n' "$unenc"; exit 1; }
    fi
    echo "== VERIFY PASS =="; exit 0
  fi

  # Tier 2
  [ -n "$O" ] && [ -n "$R" ] || die "cannot parse owner/repo from origin ($ORIGIN_URL)."
  D=$(mktemp -d); trap 'rm -rf "$D"' EXIT; fail=0
  echo "== Verify Tier 2 on $O/$R =="
  refs=$(git ls-remote "https://github.com/$O/$R.git" 'refs/heads/*' | awk '{print $2}')
  printf '%s\n' "$refs" | grep -qx 'refs/heads/main' && { echo "  FAIL: remote still has a plaintext refs/heads/main"; fail=1; }
  if printf '%s\n' "$refs" | grep -qx 'refs/heads/master'; then
    echo "  PASS: remote exposes refs/heads/master (gcrypt)"
  else
    echo "  FAIL: no refs/heads/master on remote — was the gcrypt push done?"; fail=1
  fi
  if git clone --quiet "https://github.com/$O/$R.git" "$D/raw" 2>/dev/null; then
    leak=0
    while IFS= read -r f; do
      b=$(basename "$f"); [[ $b =~ ^[0-9a-f]{16,}$ ]] || { echo "  FAIL: readable file on plain remote: $b"; leak=1; }
    done < <(find "$D/raw" -not -path '*/.git/*' -type f)
    [ "$leak" -eq 0 ] && echo "  PASS: plain clone is opaque (only hash-named blobs)" || fail=1
  else
    echo "  NOTE: plain clone failed (private repo without creds?) — skipped opacity check"
  fi
  if git clone --quiet "gcrypt::https://github.com/$O/$R.git" "$D/unlocked" 2>/dev/null \
     && git -C "$D/unlocked" checkout main --quiet 2>/dev/null; then
    [ -f "$D/unlocked/AGENTS.md" ] && echo "  PASS: gcrypt clone decrypts to the real tree" \
      || { echo "  FAIL: gcrypt clone decrypted but the tree looks wrong (no AGENTS.md)"; fail=1; }
  else
    echo "  FAIL: gcrypt clone/checkout failed — key missing, or push never landed"; fail=1
  fi
  [ "$fail" -eq 0 ] && { echo "== VERIFY PASS =="; exit 0; } || { echo "== VERIFY FAIL =="; exit 1; }
fi

# =============================================================================
# ENABLE — TIER 1 (git-crypt)
# =============================================================================
if [ "$TIER" = 1 ]; then
  command -v git-crypt >/dev/null 2>&1 || die "git-crypt not installed (apt-get install git-crypt / brew install git-crypt)."
  [ -e .git/git-crypt/keys/default ] && die "git-crypt already initialized here — nothing to do (see --verify)."
  [ -f .gitattributes ] && die ".gitattributes already exists — refusing to clobber; enable Tier 1 by hand (spec.content-encryption.md)."

  timing_guard
  confirm_local_vault

  echo "-> git-crypt init"
  git-crypt init >/dev/null
  echo "-> writing .gitattributes (encrypts 2_using_timeline/** and 3_generates_wiki/**)"
  printf '%s\n' "$GITATTRIBUTES_BODY" > .gitattributes
  git add .gitattributes
  echo "-> re-encrypting pre-existing content-path files (wiki.index.md) via git-crypt status -f"
  git-crypt status -f >/dev/null
  git commit -q -m "enable content encryption (Tier 1, git-crypt)"

  # confirm the catalog actually encrypted — the single easiest Tier-1 mistake
  if git-crypt status -e 2>/dev/null | grep -q '3_generates_wiki/wiki.index.md'; then
    echo "-> confirmed: wiki.index.md is encrypted"
  else
    die "wiki.index.md did NOT encrypt — investigate before pushing (do not push plaintext catalog)."
  fi
  echo

  cat <<'EOF'
Tier 1 enabled and committed. TWO things remain — both yours:

  1. BACK UP THE KEY (it IS your data; lost key = permanently undecryptable):
       git-crypt export-key /dev/stdout | base64 -w0 ; echo
     Store that one line in your password manager, then TEST-restore it.
     Full verified procedure: 1_agentic_config/admin/encryption.checklist.git-crypt.key-backup.md

  2. PUSH (plain — no pinentry for Tier 1):
       git push origin main

Then verify:
     ./1_agentic_config/scripts/enable-encryption.sh --tier 1 --verify
EOF
  exit 0
fi

# =============================================================================
# ENABLE — TIER 2 (git-remote-gcrypt)
# =============================================================================
command -v git-remote-gcrypt >/dev/null 2>&1 || die "git-remote-gcrypt not installed (apt-get install git-remote-gcrypt)."
command -v gpg  >/dev/null 2>&1 || die "gnupg not installed (apt-get install gnupg)."
command -v gh   >/dev/null 2>&1 || die "gh (GitHub CLI) not installed — needed for the STEP ZERO repo reset."
[ -n "$O" ] && [ -n "$R" ] || die "cannot parse owner/repo from origin ($ORIGIN_URL)."

# resolve the signing key fingerprint (derived unless --fpr overrides)
if [ -z "$FPR" ]; then
  nsec=$(gpg --list-secret-keys --with-colons 2>/dev/null | grep -c '^sec:' || true)
  [ "$nsec" -ge 1 ] || die "no GPG secret key found — generate/back one up first (encryption.checklist.GPG-gcrypt.key-backup.md)."
  [ "$nsec" -eq 1 ] || die "multiple GPG secret keys present — disambiguate with --fpr <40-hex>."
  FPR=$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr:/{print $10; exit}')
fi
gpg --list-secret-keys "$FPR" >/dev/null 2>&1 || die "no secret key matches fingerprint $FPR."

timing_guard
confirm_local_vault

# --- Step 2: show + confirm the ORIGIN remote state before touching it ---
echo
echo "Origin remote          : $ORIGIN_URL"
echo "Target GitHub repo     : github.com/$O/$R"
echo "Signing key            : $FPR"
echo "Current remote branches:"
remote_refs=$(git ls-remote "https://github.com/$O/$R.git" 'refs/heads/*' 2>/dev/null | awk '{print $2}')
if [ -z "$remote_refs" ]; then
  echo "  (none — remote empty or unreachable)"
else
  printf '  %s\n' $remote_refs
  if printf '%s\n' "$remote_refs" | grep -qx 'refs/heads/main'; then
    echo "  -> plaintext 'main' present; STEP ZERO will wipe it (this is why the reset is needed)."
  elif printf '%s\n' "$remote_refs" | grep -qx 'refs/heads/master'; then
    echo "  -> looks already-gcrypt (only master); re-running resets and re-pushes."
  fi
fi
echo
echo "STEP ZERO will DELETE and recreate github.com/$O/$R (remote history wiped; LOCAL vault untouched)."
printf "Proceed with the reset? Type 'yes': "
read -r go || die "no input on stdin — aborted."
[ "$go" = "yes" ] || die "aborted, nothing deleted."

echo "-> deleting $O/$R ..."
gh repo delete "$O/$R" --yes
echo "-> recreating $O/$R (private) ..."
gh repo create "$O/$R" --private >/dev/null
git config --unset remote.origin.gcrypt-id 2>/dev/null || true
git remote set-url origin "gcrypt::https://github.com/$O/$R.git"
git config remote.origin.gcrypt-participants "$FPR"
echo "-> origin is now gcrypt:: with participant $FPR"
echo

cat <<EOF
NEXT — first encrypted push (a MODAL pinentry will ask for the key passphrase):

  ⚠ Copy the GPG passphrase to your clipboard FIRST (the dialog grabs focus).
    git push origin main

Then verify:
    ./1_agentic_config/scripts/enable-encryption.sh --tier 2 --verify

(gpg-agent caches ~10 min, so the dialog may not reappear — never trust "no dialog";
the --verify step is what confirms the push actually landed.)
EOF
