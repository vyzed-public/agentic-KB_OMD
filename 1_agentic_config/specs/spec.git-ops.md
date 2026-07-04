---
title: Git Ops — Multi-Vault Clone/Upstream Workflow
created: 2026-07-02
updated: 2026-07-02
description: How knowledge-base vaults relate to the shared framework repo via a two-remote (origin + upstream) model — back up to your own origin, pull framework fixes from upstream, keep the framework repo content-free. Covers roles, setup.sh, the content-guard hook, doctor.sh, and the seed-file topology.
---

# Git Ops — Multi-Vault Clone/Upstream Workflow

## The model in one paragraph
The framework (schema, specs, scripts, config) lives once in the **framework repo** `agentic-KB_OMD`. Each knowledge base is its **own repo, cloned from the framework** and renamed to its topic (e.g. `akb-omd_astronomy`) — **not** a GitHub fork (GitHub caps those at one per account; see [[checklist.new-wiki-project]] §0 for the create recipe). A vault has **two remotes**: `origin` = its own repo (push everything here — your backup and how you propagate to new hosts) and `upstream` = the framework repo, **fetch-only** (pull framework fixes; you can never push content into the shared framework). Framework fixes reach the framework repo only from a content-free **gateway** clone. This is "clone and keep pulling": one source of truth for internals, independent backed-up content per vault.

## Roles
| Clone | `origin` | `upstream` | commits content? | content-guard hook |
|---|---|---|---|---|
| **Vault** (`akb-omd_<topic>`) | its own repo | framework (fetch-only) | yes → own origin | off |
| **Gateway** (`agentic-KB_OMD`) | framework repo | — | no | **on** |

## Setup (per clone, once)
`setup.sh` does the wiring — run it right after cloning:
- Vault: `./setup.sh --role vault --upstream <framework-repo-url>` → adds `upstream`, push-disabled.
- Gateway: `./setup.sh --role gateway` → activates the content-guard hook (`core.hooksPath=.githooks`).

Git will **not** auto-run a cloned repo's hooks (a security design choice), so this activation step is required once per clone — it can't be skipped and still have the guard.

## Everyday commands
- **Back up your work:** `git push origin main`
- **Pull a framework fix (rare):** `git pull upstream main`. Your content survives; the pull only touches framework files (proven: `upstream` carries no content, so a 3-way merge keeps your files).
- **Publish a framework fix (gateway only):** edit → `git commit` → `git push origin main`.

## What keeps the framework repo clean (the invariant)
The framework repo's content dirs stay empty and its seed files (`wiki.index.md`, `_agent_logs.md`) stay frozen **because only the content-free gateway pushes to it.** Two mechanisms enforce it:
1. **`upstream` is push-disabled** in every vault (via `setup.sh`) — a vault physically cannot push into the framework.
2. **The content-guard `pre-commit` hook** (active in the gateway) aborts any commit that stages a **content path**. Content paths are defined once in **`1_agentic_config/scripts/content-paths`** — the single source of truth; never re-list them elsewhere. `.gitkeep` and the seed files are exempt.

## Health & recovery
- **`1_agentic_config/scripts/doctor.sh`** — run anytime; flags the dangerous condition (content tracked in a framework/gateway clone) and reports hook/remote state.
- If a slip happens, follow the break-glass runbook: **`1_agentic_config/admin/RUNBOOK.git-ops.md`**.

## Format migrations to seed files
If the framework changes the *format* of `wiki.index.md` or `_agent_logs.md`, do **not** push it as an edit to the frozen seed (it would conflict in every vault). Ship it as a versioned instruction and let each vault's agent update its own local copy — keeping the seed frozen and the invariant intact.
