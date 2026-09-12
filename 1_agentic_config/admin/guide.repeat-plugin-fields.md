# Guide: Setting `repeat` and Spaced Fields (Repeat plugin)

A concise reference for scheduling note reviews with the **Repeat** plugin
(`prncc/obsidian-repeat-plugin`). Two frontmatter fields do all the work: `repeat` (you set it)
and `due_at` (the plugin manages it).

---

## The two fields

- **`repeat:`** — the schedule. You write this. Two modes (below).
- **`due_at:`** — when the note next surfaces. **The plugin writes and updates this on review.**
  You normally don't touch it. Format is full ISO with milliseconds + timezone offset, e.g.
  `due_at: 2026-09-11T23:01:24.352-07:00`.

> **Gotcha:** if you ever set `due_at` by hand, make it a **Text** property (not Date/Date-&-time)
> and match that exact ISO format, or the plugin ignores it and falls back to the file's creation
> time (which on this vault reads as 1970 — the source of nonsense intervals).

Alternatively, ==you can use the Repeat plugin's "skip for 5 minutes" button to set the time field to a safely formatted value.==

---

## Mode 1 — Periodic (fixed cadence)

A steady drumbeat. Each review advances `due_at` by the same interval. Good for a recurring
**nudge** ("remind me until this becomes a habit").

```yaml
repeat: every 1 month
```

Accepted forms:

- Named: `daily`, `weekly`, `monthly`, `yearly`
- Interval: `every 2 weeks`, `every 3 days`, `every 6 months`
- Optional time of day: `every 1 week at 9:00 AM`

**Review buttons:** `5 minutes (skip)` + one button for the next fixed interval.

---

## Mode 2 — Spaced (graded, within a band)

Add the `spaced` keyword. On review you pick how far out it goes.

```yaml
repeat: spaced every 1 week
```

**Review buttons:** `5 minutes (skip)` + four grade buttons at **0.5×, 1×, 1.5×, 2×** the base
period (measured from now). Shaky recall → 0.5× (sooner); solid → 2× (later).

**Important limit:** this is *not* Anki-style expansion. The interval always stays within
**0.5×–2× of the base** — `spaced every 1 week` only ever lands ~3–14 days out. To make intervals
genuinely climb, raise the **base** yourself over successive cycles
(`spaced every 2 months` → `every 3 months` → `yearly`). Manual, but unbounded.

---

## Quick reference

| Want | Set |
|---|---|
| Fixed monthly nudge | `repeat: every 1 month` |
| Fixed, twice a month | `repeat: every 2 weeks` |
| Graded review, ~weekly | `repeat: spaced every 1 week` |
| Stop reminding this note | delete the `repeat:` line, or use command **"Repeat: Never repeat this note"** |

**Reviewing:** command palette → **"Repeat: Review due notes"** (or the ribbon icon). The
status-bar "N due" counter is your passive nudge. Skip defers 5 minutes; the interval/grade
buttons schedule the real next date.

---

## Alternate plugin (for future wikis): Obsidian Spaced Repetition

If a future vault needs **flashcard / quiz / memorization** functionality — genuine SM-2-style
review where intervals *automatically* expand as you learn — use **Obsidian Spaced Repetition**
(`st3v3nmw/obsidian-spaced-repetition`) instead of (or alongside) Repeat. It supports:

- **Flashcards** (`?` / `::` separators, cloze deletions, quiz-style Q&A in-note).
- **Whole-note review** graded Hard / Good / Easy, with a real SM-2 algorithm that grows the
  interval automatically (stored in `sr-due` / `sr-interval` / `sr-ease` frontmatter).

**When to pick which:**

- **Repeat** — recurring *nudge*; resurface a note until you adopt it, then retire it. (This vault's job.)
- **Obsidian Spaced Repetition** — *retention*; memorize material and see it progressively less often.

(FSRS-based plugins are a more modern algorithm than SM-2 and worth a look if retention is the goal —
verify current maintenance before adopting.)
