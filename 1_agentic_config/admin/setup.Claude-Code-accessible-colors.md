# Terminal Color Fix: Thinking Indicator

The Claude Code thinking indicator (`✺ Thinking…`) defaults to a dark red that is nearly invisible on a black terminal background. Here is how to fix it.

## The Fix

**Step 1: Remap your terminal's ANSI color palette.**

Change Color 1 (red) and Color 9 (bright red) to amber/gold values. In GNOME Terminal via gsettings:

```bash
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")/ palette "['#FF8C00', ...]"
```

Or just open your terminal's preference UI and set:
- Color 1 (red) → `#FF8C00` (amber)
- Color 9 (bright red) → `#FFC800` (bright gold)

**Step 2: Set `dark-ansi` theme in Claude Code.**

In `~/.claude/settings.json`:

```json
{
  "theme": "dark-ansi"
}
```

This tells Claude Code to use ANSI palette colors instead of hardcoded RGB values, so the thinking indicator picks up your remapped amber instead of the built-in red.

Restart Claude Code after making this change.

---

## What Not to Try

There is a `shimmerColor` key inside the Claude Code binary, but it is not exposed in `settings.json`. Setting it there does nothing. The palette remap + `dark-ansi` combination is the only lever available without patching the binary.

GitHub issue tracking exposure of `shimmerColor`: https://github.com/anthropics/claude-code/issues/69229

---

## Bonus: Statusline Threshold Color

If you use a custom statusline script (`~/.claude/statusline-command.sh`), change any ≥80% warning highlights from bold red (`\033[01;31m`) to bold yellow (`\033[01;33m`) for the same reason — red on black is hard to read.
