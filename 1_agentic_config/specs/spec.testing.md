---
title: Testing the Git-Ops Framework
created: 2026-07-02
updated: 2026-07-02
description: How to run and understand the local test harnesses that verify the multi-vault git-ops machinery (content-guard hook, setup.sh, fork/upstream workflow, doctor.sh), plus the skeleton builder and link checker. Fully local — no GitHub or Obsidian needed.
---

# Testing the Git-Ops Framework

These harnesses verify the machinery described in [[spec.git-ops]]. They are **fully local**: each spins up throwaway git repos in a temp dir and asserts on real git behavior. **No GitHub, no Obsidian, no network** — you need only `git` and `bash`. They test the **actual shipped artifacts** (`.githooks/pre-commit`, `setup.sh`, `1_agentic_config/scripts/{content-paths, doctor.sh}`), not copies — so a green run means the real machinery works.

## Run everything
```
bash 1_agentic_config/tests/run-all.sh
```
Exit 0 and `✅ ALL GIT-OPS HARNESSES PASSED` = healthy.

## When to run it
Run `run-all.sh` **whenever you change a git-ops artifact** — the pre-commit hook, `content-paths`, `setup.sh`, or `doctor.sh` — and **always before publishing a framework fix from the gateway**. If it is red, do not push.

## What each harness proves
- **`test-hook.sh`** — the content-guard `pre-commit` hook blocks knowledge-base *content* from being committed into the framework repo, while allowing framework files, `.gitkeep`, and the two seed files (`wiki.index.md`, `_agent_logs.md`).
- **`test-setup.sh`** — `setup.sh` wires remotes per role: a **vault** gets `upstream` fetch-only and no hook; a **gateway** gets the content-guard activated; a vault missing `--upstream` errors out.
- **`test-workflow.sh`** — the whole fork/upstream loop on local bare repos: content backs up to the vault's own `origin`; a framework fix pulled from `upstream` lands in the vault; **the vault's content survives the pull**; the framework repo never receives content.
- **`test-doctor.sh`** — `doctor.sh` detects a contamination slip (content committed into a framework/gateway clone), names the offending file, and reports clean after the recovery steps.

## Tools
- **`1_agentic_config/tools/build-skeleton.sh [SRC] [DST]`** — produce a clean, content-free framework skeleton from a working vault (SRC defaults to this repo root; DST to `/tmp/wiki-skeleton`). Strips all knowledge-base content + keys, resets `wiki.index.md` and the log hub, `.gitkeep`s the empty data dirs. This is how the framework repo's contents are (re)generated.
- **`1_agentic_config/tools/skel-check.py [DIR]`** — scan a vault/skeleton for dangling `[[wikilinks]]` (DIR defaults to CWD). Run it after building a skeleton: `python3 1_agentic_config/tools/skel-check.py /tmp/wiki-skeleton`.

## If a harness fails
A red harness means a git-ops artifact changed in a way that broke a guarantee. The failing case name says exactly what broke — inspect the artifact it exercises, fix it, re-run. For operational recovery of a *live* vault or framework repo (as opposed to a test failure), see [[RUNBOOK.git-ops]].
