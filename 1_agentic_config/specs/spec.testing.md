---
title: Testing the Git-Ops Framework
created: 2026-07-02
updated: 2026-07-06
description: How to run and understand the local test harnesses that verify the multi-vault git-ops machinery (content-guard hook, setup.sh, fork/upstream workflow, doctor.sh) and the ingest attachment localizer, plus the skeleton builder and link checker. Fully local — no GitHub or Obsidian needed.
---

# Testing the Git-Ops Framework

These harnesses verify the machinery described in [[spec.git-ops]]. They are **fully local**: each spins up throwaway git repos in a temp dir and asserts on real git behavior. **No GitHub, no Obsidian, no external network** — you need only `git`, `python3`, and `bash` (the localizer harness uses a throwaway *localhost* HTTP server). They test the **actual shipped artifacts** (`.githooks/pre-commit`, `setup.sh`, `1_agentic_config/scripts/{content-paths, doctor.sh, attachment-localize.py, timeline-guard.sh}`), not copies — so a green run means the real machinery works.

## Run everything
```
bash 1_agentic_config/tests/run-all.sh
```
Exit 0 and `✅ ALL HARNESSES PASSED` = healthy.

## When to run it
Run `run-all.sh` **whenever you change a git-ops artifact** — the pre-commit hook, `content-paths`, `setup.sh`, or `doctor.sh` — and **always before publishing a framework fix from the gateway**. If it is red, do not push.

## What each harness proves
- **`test-hook.sh`** — the content-guard `pre-commit` hook blocks knowledge-base *content* from being committed into the framework repo, while allowing framework files, `.gitkeep`, and the two seed files (`wiki.index.md`, `_agent_logs.md`).
- **`test-setup.sh`** — `setup.sh` wires remotes per role: a **vault** gets `upstream` fetch-only and no hook; a **gateway** gets the content-guard activated; a vault missing `--upstream` errors out.
- **`test-workflow.sh`** — the whole fork/upstream loop on local bare repos: content backs up to the vault's own `origin`; a framework fix pulled from `upstream` lands in the vault; **the vault's content survives the pull**; the framework repo never receives content.
- **`test-doctor.sh`** — `doctor.sh` detects a contamination slip (content committed into a framework/gateway clone), names the offending file, and reports clean after the recovery steps.
- **`test-localizer.sh`** *(ingest, not git-ops)* — `scripts/attachment-localize.py` (ingest step 10) downloads remote image embeds and rewrites them to local `![[…]]` wikilinks, and — critically — **fails loud, never silent**: a dead URL or a zero-byte download exits non-zero and leaves the note UNCHANGED, so the caller stops instead of filing a note without its images. Stands up a throwaway localhost HTTP server; needs `python3`.
- **`test-guard.sh`** *(ingest/immutability, not git-ops)* — the LOCATION-BASED `scripts/timeline-guard.sh` PreToolUse hook: STAGED (top-level `2_using_timeline/`) is mutable, FILED (`YYYY/MM/…`) is agent-immutable, deletion is curator-only in both zones, and the sole staged→filed **seal** move is allowed. Feeds crafted payloads to the real hook and asserts allow/deny across every write vector (redirect, `sed -i`, `tee`, `cp`, `truncate`, interpreters, `Write`/`Edit`). Needs `jq`.

## Tools
- **`1_agentic_config/tools/build-skeleton.sh [SRC] [DST]`** — produce a clean, content-free framework skeleton from a working vault (SRC defaults to this repo root; DST to `/tmp/wiki-skeleton`). Strips all knowledge-base content + keys, resets `wiki.index.md` and the log hub, `.gitkeep`s the empty data dirs. This is how the framework repo's contents are (re)generated.
- **`1_agentic_config/tools/skel-check.py [DIR]`** — scan a vault/skeleton for dangling `[[wikilinks]]` (DIR defaults to CWD). Run it after building a skeleton: `python3 1_agentic_config/tools/skel-check.py /tmp/wiki-skeleton`.

## If a harness fails
A red harness means a git-ops artifact changed in a way that broke a guarantee. The failing case name says exactly what broke — inspect the artifact it exercises, fix it, re-run. For operational recovery of a *live* vault or framework repo (as opposed to a test failure), see [[RUNBOOK.git-ops]].
