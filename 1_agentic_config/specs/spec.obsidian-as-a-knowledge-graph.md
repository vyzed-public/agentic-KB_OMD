---
title: Obsidian as a Knowledge Graph
created: 2026-06-27
updated: 2026-06-27
description: The logical model of this vault as a knowledge graph — wikinotes as nodes, wikilinks as edges, the two node classes (CTN and GWN), and how to traverse the graph for discovery. The graph-view companion to spec.directory-structure (the physical view).
---

# Obsidian as a Knowledge Graph

Our Personal Knowledge Base (PKB) is a Knowledge Graph (KG) expressed in Obsidian Markdown (OMD).

## Structure: wikinotes are nodes, wikilinks are edges

You should think of our PKB as a knowledge graph (KG) where: 
- An Obsidian wikinote acts as a NODE in the KG
- An OMD wikilink (often expressed as `[[wikilink]]`) acts as an EDGE in the KG.

Note the VERY IMPORTANT difference in spelling AND meaning between "note" and "node":
- A NODE operates in the ABSTRACT context of graph theory applied to the KG
- A NOTE operates in the CONCRETE context of an Obsidian vault acting as a KG.

Reason about this with graph concepts — degree and hubs, paths, clusters, inbound vs. outbound links.

## Note Types: CTN (Collected Timeline Note) & GWN (Generated Wiki Note)

In this KG, the NOTES implement a descending ladder of discovery, as follows:
- There are two classes of NOTES acting as NODES in this KG.
	1. Collected Timeline Note (CTN): 
		- Typically imported via the Obsidian Web Clipper
		- Usually has an outbound wikilinked URL from the originating source
		- Has special properties for:
			- `purpose:` to record WHY this knowledge is being curated
			- `projects:` to identify WHERE this knowledge might be applied
		- Low INTERNAL connectivity within our KG:
			- Things tend to point in — TOWARDS the CTNs
			- usually only a single inbound wikilink, FROM a wikinote in `sources/`
			- often contain outbound wikilinks to URLs that are EXTERNAL to the vault
			- occasionally wikilinked to "attached" resource files or other CTNs in a "cluster"
	2. Generated Wiki Note (GWN): 
		- HIGHLY-compressed ("lossy") summaries and concepts from the CTNs
		- High INTERNAL connectivity within the KG
			- to other GWNs via multiple wikilinks
		- 4 types: concepts, entities, sources, and synthesis
			- **Projects are entities, not a fifth type.** A `project_<slug>` page (from a CTN's `projects:` property) is an **entity** GWN in `entities/` — the `project_` prefix is a naming convention only.
		- Note that GWNs in "sources/"  have wikilinks to ingested CTNs
		- In our KB, GWNs point OUT at other notes
			- versus CTNs, which get pointed "to", by GWNs in `sources/`

## Use the knowledge graph structure for multiple discovery paths AND cycles

The GWNs and CTNs and their wikilinks implement a knowledge graph (KG) that enables a descending ladder of discovery in this PKB. 

Discovery paths exist in ***BOTH*** the GWNs ***AND*** the CTNs — and in the connections and conceptual relationships between them.

### You should traverse the GWNs and seek unexpected/unexplored Topic Connections

Your discovery path almost always involves traversing the KG to discover connections in the GWNs.
Real value is generated in discovering the unexpected connections that may yield new synthesis.

### You should keep the user's PURPOSE and INTENT in mind, and mine the CTNs for similar

REMEMBER, it is also VERY IMPORTANT to map the INTENT of the user's current QUERY onto the `purpose:` and `projects:` properties of the CTNs.

### You should understand the descending ladder of discovery from general to specific

UNDERSTAND that the GWNs are SUMMARIES — deliberately intended to be VERY LOSSY.  
- These layers of the KG are designed to capture conceptual connections, not details.  
- Specific details can be recovered from the CTNs. 

### You should explore unexpected CYCLES from GWNs to CTNs back to GWNs

UNDERSTAND that details in the CTNs may yield ADDITIONAL IDEAS for exploring the KG:
-  The `purpose:` and `projects:` properties of the CTNs may map to GWNs. A `projects:` entry maps to an **entity** GWN — the `project_<slug>` page in `entities/` (projects are entities, not a separate type).
- Concepts in the CTNs can be searched in the GWNs and re-traversed in the KG
- There could be MULTIPLE CYCLES 
	- between the details in the CTNs 
	- and the concepts and connections in the GWNs
