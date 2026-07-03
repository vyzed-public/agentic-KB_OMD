Perform a full ingest of the file named in $ARGUMENTS from `2_using_timeline/`, with the curator interview always included (never skipped).

Follow the standard ingest process defined in CLAUDE.md, with the interview step mandatory:

1. Read `2_using_timeline/$ARGUMENTS`.
2. Present 3–5 key takeaways; discuss briefly.
3. Run the curator interview — all three questions in order, no skip offer:

   **Q1: Purpose (immediate intention or future use)?**
   After they answer, distill into a concise 1–2 sentence statement and offer it back for approval before recording it.
   **Q2: Any category suggestions?**
   **Q3: For any specific project(s)?**

   Apply the Q2 conflation check as specified in CLAUDE.md: compare any suggested category against existing concept pages before accepting it; surface overlaps and let the human decide.

4. Use interview answers to populate `purpose:` and `projects:` frontmatter and to guide cluster/category decisions throughout.
5. Continue with standard ingest steps 4–9 from CLAUDE.md.

---

**Why the interview matters (the two-value thesis):** Q2 (categories + conflation check) and Q3 (projects) are how this source gets **placed into the wiki's relationship network** — *value source #1*, the expensive networking work the curator should never have to do at collection time. Do that placement well. But keep the resulting source summary **lossy**: summarize close-but-compressed and let cross-references carry the value — never copy the timeline artifact up into the summary. Detail stays one rung down the inference ladder (*value source #2*). See `1_agentic_config/admin/mission.rescue-the-curator.md` and the "Why This Works" section of `AGENTS.md`.
