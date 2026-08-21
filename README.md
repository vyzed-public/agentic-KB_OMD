# agentic-KB_OMD

A  [Karpathy-inspired](1_agentic_config/specs/pattern.karpathy-llm-wiki.md) knowledge base in Obsidian-flavored markdown.
## Purpose: [Solving the Combinatoric Load of Knowledge Base Curation](1_agentic_config/admin/mission.rescue-the-curator.md)

The problem with every previous generation of knowledge management tools is that they made the same fatal demand: **a human curator must wire the network at collection time.**  That demand imposes **exponentially increasing friction as the number of notes grows.** 

The combinatoric explosion of possible connections outruns the human's capacity to maintain them.  This is -- let's face it... stressful.

Agentic AI lets us separate knowledge *collection* from knowledge graph *networking*.  This is... a really good use for this technology.
## Start here

New knowledge base? Follow **[`1_agentic_config/admin/checklist.new-wiki-project.md`](1_agentic_config/admin/checklist.new-wiki-project.md)** top to bottom — it's the single entry point and routes you to every other doc (git setup, Obsidian tooling, daily notes, bootstrapping the wiki) when you need them.

Don't hand-copy files or fork on GitHub — the checklist's §0 has the supported "clone into your own repo" recipe.
## Session continuity

Resume work with **`/resume`** — it loads the durable handoff and gives a status report before anything new starts. Snapshot the session with **`/handoff`** before you stop. Handoffs live in the gitignored `_dev/` directory (a durable `_handoff.current-map.md` plus timestamped `_handoff.*` bridges).
