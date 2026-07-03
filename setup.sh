#!/usr/bin/env bash
# setup.sh — one-time per-clone setup for an agentic-KB.
#
#   ./setup.sh --role vault --upstream <framework-repo-url>   # a knowledge-base vault (default)
#   ./setup.sh --role gateway                                 # the content-free framework gateway
#
# VAULT:   origin = your own repo (push content here = backup). Adds `upstream` = the
#          framework repo, set FETCH-ONLY so you can pull framework fixes but can never
#          push content into the shared framework. Does NOT activate the content-guard.
# GATEWAY: a clone of the framework repo kept content-free. Activates the content-guard
#          pre-commit hook (core.hooksPath) so content can't be committed into it.
set -euo pipefail
ROLE=vault
UPSTREAM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --role)     ROLE="${2:-}"; shift 2;;
    --upstream) UPSTREAM="${2:-}"; shift 2;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "setup.sh: unknown argument '$1'" >&2; exit 2;;
  esac
done

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

case "$ROLE" in
  vault)
    [ -n "$UPSTREAM" ] || { echo "ERROR: --role vault requires --upstream <framework-repo-url>" >&2; exit 2; }
    if git remote | grep -qx upstream; then
      git remote set-url upstream "$UPSTREAM"
    else
      git remote add upstream "$UPSTREAM"
    fi
    git remote set-url --push upstream DISABLED   # fetch-only: cannot push content into the framework
    echo "vault ready: upstream -> $UPSTREAM (push DISABLED)."
    echo "  back up your content:   git push origin main"
    echo "  pull framework fixes:   git pull upstream main"
    ;;
  gateway)
    git config core.hooksPath .githooks
    echo "gateway ready: content-guard hook activated (core.hooksPath=.githooks)."
    echo "  this clone must stay content-free; publish framework fixes with: git push origin main"
    ;;
  *)
    echo "ERROR: --role must be 'vault' or 'gateway' (got '$ROLE')" >&2; exit 2;;
esac
