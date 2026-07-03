---
title: RUNBOOK — Git Ops Break-Glass
created: 2026-07-02
updated: 2026-07-02
description: Self-contained emergency recovery for the multi-vault git workflow. Assumes zero prior context. Symptom → cause → fix. Ships in the framework so every clone carries its own recovery instructions.
---

# RUNBOOK — Git Ops Break-Glass

**Read this if a `git pull`, `git push`, or commit is behaving strangely in a knowledge-base vault or the framework gateway — and you have no memory of how any of this was set up.** It is deliberately self-contained.

## 30-second model
- The **framework repo** (`agentic-KB_OMD`) holds shared machinery and MUST stay content-free; its `wiki.index.md` / `_agent_logs.md` are frozen empty **seeds**.
- Each **vault** (`akb-omd_<topic>`) is a fork: `origin` = its own repo (your content backup), `upstream` = the framework (fetch-only).
- The single rule that keeps everything working: **no knowledge-base content is ever committed into the framework repo.** Everything below detects and undoes a violation of that rule.

## First move, always: run the doctor
```
bash 1_agentic_config/scripts/doctor.sh
```
It prints `HEALTHY`, or names any content wrongly tracked in this clone.

## Symptom → cause → fix

**S1 — `doctor.sh` says "knowledge-base CONTENT is tracked" (in a gateway / the framework repo).**
Cause: a content file was committed into the framework repo — a *slip* (usually a `git commit --no-verify`, or a clone whose hook was never activated). This is what breaks pulls for other vaults.
Fix, in the gateway/framework clone:
```
git rm -r --cached <the paths doctor listed>
git commit -m "recover: remove content from framework repo"
git push origin main
bash 1_agentic_config/scripts/doctor.sh    # confirm HEALTHY
```

**S2 — `git pull upstream` in a vault reports a conflict on `wiki.index.md` or a log file.**
Cause: the framework's seed got unfrozen (an S1 slip already propagated). 
Fix: first do **S1** in the gateway to re-freeze the seed and push it. Then, in the vault, keep YOUR version:
```
git checkout --ours 3_generates_wiki/wiki.index.md    # --ours = the vault's content
git add 3_generates_wiki/wiki.index.md
git commit --no-edit
```
Never accept "theirs" for a seed file — "theirs" is the empty framework seed; yours holds your knowledge.

**S3 — you accidentally pushed content from a vault toward the framework.**
Check: `git remote get-url --push upstream` should print `DISABLED`. If it doesn't, `upstream` push wasn't disabled — re-run `./setup.sh --role vault --upstream <url>`, then do **S1** in the gateway to clean the framework repo.

**S4 — the content-guard didn't fire in the gateway.**
Check: `git config --get core.hooksPath` should print `.githooks`. If not, re-run `./setup.sh --role gateway`.

## Prevention
- Every clone runs `setup.sh` **once** (vault or gateway role).
- Never `git commit --no-verify` in the gateway.
- Run `doctor.sh` whenever anything feels off.
