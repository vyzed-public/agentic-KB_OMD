# Mission: Rescue the Curator

Our INTENT:  Why this architecture exists; Where its value lives. 
This is the foundational rationale; the operational rules in `AGENTS.md` are downstream of it. 
When a rule and this document seem to disagree, this document states the INTENT — fix the rule.

---

## 1. The problem with every knowledge management tool

Evernote → OneNote → Notion → Roam → TiddlyWiki.  You name it. None of them were ***ever*** really going to work — not against the unavoidable combinatorics of knowledge graphs and the straitjacket of rigid-syntax retrieval.

Every one of them made the same fatal demand: **a human curator must wire the network at collection time.** Name it now. Tag it now. Link it now. Bundle relevant attachments now. File it in the right place now. Decide its relationships to everything already captured — now, while you're under the gun, juggling competing and conflicting priorities, with a finite amount of cognitive energy inside one single human light cone of experience.

That demand imposes **exponentially increasing friction as the number of notes grows.** The combinatoric explosion of possible connections outruns the human's capacity to maintain them. The best and brightest of us always knew this, or at least felt it as a **low-frequency background hum of anxiety** — but we bravely trudged on, from approach to approach, from product to product, certain the next tool would fix it. None ever really did. None ever really could. The bottleneck was never the tool. ==*The problem is the demand to make knowledge network connections at **collection** time.*==

One compelling solution is to couple a user directed knowledge base tool (such as Obsidian) with an AI model driven by an agent harness:

```
[User] <====> [Obsidian Markdown] <====> [Agentic AI]
```

## 2. Agentic AI lets us separate knowledge *collection* from knowledge graph *networking*

This architecture's first core move is to **split the two activities that every prior tool fused:**

- **Collection** happens in the "collection layer" of the **user timeline**: 
	- It is cheap, append-only, lossless, and incremental. 
	- You drop an artifact in and you are *done* — **zero networking obligation at capture time.** 
	- Adding the 5,000th note costs what the 5th did. 
	- This is the only way collection scales against a human's finite energy.
- **Networking** happens in the "network layer" of the **generated wiki**: 
	- It is done by the **LLM agent, after the collection event(s).** 
	- We call this process: ***INGESTION***
	- The agent weaves the wikilinks, the cross-references, the contradictions, the clusters — the entire relationship graph — without the human ever paying the collection-time cognitive tax.

Understand that the knowledge network **does not and cannot exist in the user timeline.** Timeline notes are gathered by the user, independently, over time; the connections between them are precisely what's too expensive to establish at collection time. The agent builds them downstream, where the cost is borne by compute, not by a stressed human trying to meet a deadline.

## 3. Agentic AI lets us (re)discover our self curated knowledge using natural language inference 

Once we release the curator's cognitive burden of ingestion time knowledge graphing, the value of our knowledge base moves to two places:

1. **The relationship network in the generated wiki.** This is the previously cognitively expensive thing made free. It is the product. The wiki's worth is its *graph* — what links to what, what corroborates, what contradicts, what clusters — not the prose of any single page.

2. **The inference ladder** (of progressive disclosure): a `wiki.index` → generated wiki **summary** → **original** (timeline note *or* the web reference inside it) — descending only as far as a given question needs. Most questions are answered high on the ladder. Some require dropping to the lossless original. An agent-driven inference ladder is now the retrieval model;  all the frustrations of rigid query syntax can be abandoned.

The value can be harvested by agent-driven driven **permutations** and **cyclic inference loops** — which are enabled by both:
- Permutations and cycles on the knowledge graph defined by the notes and wikilinks within the generated wiki; 
- Additional cycled driven by findings from the details in the user timeline.  These may be **fed back into additional cycles of inference** on the generated wiki. 

## 4. Agentic AI lets us leverage lossy knowledge compression 

**The summaries in the generated-wiki are lossy by design.** The summarization of our ingestion process discards detail on purpose.  We cannot know at ingest time which details a future question will need. That is a feature, not a defect.

Therefore: **Once ingested, we never backfill timeline detail into a wiki summary to "complete" it.** Cramming every artifact detail upward defeats the compression and turns summaries into bloated copies of the originals — destroying the very thing that makes the wiki navigable.

When a query needs a detail the summary dropped, the answer is **to descend the ladder, not to fatten the summary.** The detail was never lost; it lives one rung down, in the timeline original (or its web source).  ==**The details are reachable by progressive disclosure.**==


