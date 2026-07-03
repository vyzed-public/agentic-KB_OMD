---
title: Directory Structure
created: 2026-06-22
updated: 2026-06-25
description: The canonical annotated directory tree for an agentic-KB_OMD vault — control/data-plane split, the four numbered directories, hidden config. AGENTS.md references this for the full tree.
---

# Directory Structure

Project Designation: **`agentic-KB_OMD/`**  — An agentic knowledge base in Obsidian-flavored markdown.

The project directory structure can be cloned from [the public repo](https://github.com/vyzed-public/agentic-KB_OMD) 
...and renamed to establish a destination directory: `akb-omd_<domain>` — examples:
- `mv agentic-KB_OMD/ akb-omd_astronomy`
- `mv agentic-KB_OMD/ akb-omd_oceanography`

...that can be used to instantiate an Obsidian vault to serve as a knowledge base.

Inside the vault directory, the numeric prefixes lock both sort order and reading order. 
* Essentially:  ***"This agentic config, using a timeline, generates a wiki, for collaboration."*** 
* The reading order = the data flow: config → input → knowledge → action. 

We also (implicitly) have: 
* a CONTROL PLANE = `AGENTS.md`  (+ `.claude/`)  +  the schema spec files in `1_agentic_config/` 
* a DATA PLANE = `2_using_timeline/` (Input) + `3_generates_wiki/` (Output).


```  
  vault root/                 # Instantiated vault (e.g.: akb-omd_oceanography)
  │
  ├── AGENTS.md               # SCHEMA — the canonical "law" of the control plane
  ├── CLAUDE.md               # A symlink to AGENTS.md (agent-harness compatibility)
  │                           # CRITICAL: Make edits to AGENTS.md, never CLAUDE.md!
  │
  ├── 1_agentic_config/       # CONFIG ─ for the CONTROL PLANE (agent behavior)
  │   ├── admin/              #  mission, checklists, setup docs, etc.
  │   ├── logs/               #  append-only agent logs
  │   │   ├── _agent_logs.md  #    hub note indexing every monthly file
  │   │   └── YYYY-MM.md      #    each month's entries (e.g. 2026-06.md)
  │   ├── scripts/            #  e.g. timeline-guard.sh, filename-check.sh
  │   └── specs/              #  spec.*.md references for the schema
  │
  ├── 2_using_timeline/       # INPUT ─ for the DATA PLANE                           ──┐
  │   │                       #   user collected OMD notes via web-clipper (protected) │
  │   │                                                                                | data
  │   ├── YYYY/MM/            #   Date-organized subdirectories for kept artifacts     │ plane
  │   │   └── assets/         #   Images + companion file artifacts                    │
  │   │                       #     (permanently archived, using true file extensions  │
  │   └── attachments/        #   Temporary landing zone for downloaded images         │
  │                           #     (cleared post ingestion)                           │
  │                                                                                    │
  ├── 3_generates_wiki/       # OUTPUT ─ for the DATA PLANE                            │
  │                           # KNOWLEDGE ─ the agent-built wiki (the queryable graph) │
  │   ├── wiki.index.md       #   catalog + JIT retrieval header                       │
  │   ├── sources/            #   one summary page per ingested source                 │
  │   ├── concepts/           #   topic / concept pages                                │
  │   ├── entities/           #   people / orgs / products / places                    │
  │   └── synthesis/          #   comparisons, analyses, filed Q&A                   ──┘
  │
  ├── 4_collaboration/        # ACTION  ─ joint human+agent workspace (no guard)
  │
  ├── .claude/                # (hidden) Claude Code config — commands, hooks, settings
  └── .obsidian/              # (hidden) Obsidian app config — invisible to the vault
```

### A Joint Workspace for User-Agent Collaboration occurs in `4_collaboration/`

Unlike the other three spaces (each single-owner), this is the one place the human and agent **both read and write freely — no guard**. 

It holds project-oriented working artifacts and action items, *not* specifically intended for knowledge queries. 

It is project-oriented, not timeline-oriented, and its logging conventions are TBD. 

AI operation here is expected to be light for now and may grow. 

For now, the two **behavioral** rules that govern it are: 
1. links go one way (the generated wiki never links into collaboration);
2. the only feedback path back is a cycle from collaboration back into the user timeline 
	- In other words, we ***can*** re-ingest;
	- but we never write straight into the wiki.
These two rules are schema law; see [[AGENTS|AGENTS.md]] Rules.
