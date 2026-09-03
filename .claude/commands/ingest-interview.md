Perform a full ingest of the file named in `$ARGUMENTS` from `2_using_timeline/` —
**with one override: the curator interview is mandatory and is never skipped.**

**Follow the full procedure defined in [[spec.file-ingestion]]** — the 12 steps plus
the Q1–Q5 interview — as the single source of truth. **Do not restate or re-number the
steps or the interview questions here;** that duplication is what let this command drift
out of sync with the spec. This command changes exactly one thing versus a normal ingest:

- **The interview is not skippable.** Conduct **all** of the spec's interview questions
  (Q1–Q5) in order, and **never present the "skip" option** the standard flow allows. The
  question definitions, the Q2 conflation check, and the frontmatter stamping
  (`purpose` / `projects` / `repeat` / `priority`) are exactly as the spec defines them —
  follow the spec, don't paraphrase it.

---

**Why the interview matters (the two-value thesis):** Q2 (categories + the conflation
check) and Q3 (projects) are how a source gets **placed into the wiki's relationship
network** — *value source #1*, the expensive networking the curator shouldn't do at
collection time. Keep the source summary **lossy**; let cross-references carry the value.
Detail stays one rung down the inference ladder (*value source #2*). See
`mission.rescue-the-curator.md` and the "Why This Works" section of `AGENTS.md`.
