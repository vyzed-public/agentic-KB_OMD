---
title: Claude Code UX Setup
created: 2026-06-15
updated: 2026-07-02
description: Spec for setting up a rich statusline, done-signal + "needs-you" desktop notifications, and (X11) terminal focus-return in Claude Code. Drop this file into any project and pass it to an LLM agent to replicate the setup.
---

# Claude Code UX Setup

> **Related:** [[guide.handoff-management]] — a companion primer on preserving working context across compaction and sessions. This doc tunes the *environment*; that one tunes the *workflow*.

This is an instruction file for an LLM agent (e.g. Claude Code). Its job is to set up these UX improvements in `~/.claude/`:

1. **Rich statusline** — shows a processing state label, `username:dirname`, model name, 5-hour session rate limit usage, and context window usage in the Claude Code status bar.
2. **Done-signal notification** — a silent desktop notification that pops up when Claude finishes, so you always know when it is safe to type.
3. **"Needs you" notification** — a deferred, focus-gated popup that appears when Claude has been blocked waiting on your decision or input for ~30s **and** you're not looking at the terminal (see Appendix).
4. **Terminal focus-return** — on X11, raises the terminal back to the foreground when Claude finishes or a deferred "needs you" fires (see Appendix).

Read this file, then implement everything below. Do not ask for confirmation between steps — complete the full setup in one pass.

---

## Prerequisites

Verify these are installed before proceeding. If any are missing, tell the user and stop.

```bash
which jq           # JSON parsing for statusline
which notify-send  # desktop notifications (libnotify)
which xdotool      # (optional, X11) terminal focus-return — see Appendix
```

`jq` → `sudo apt install jq`. `notify-send` is part of `libnotify-bin` (`sudo apt install libnotify-bin`). For the focus-return feature (Appendix): `sudo apt install xdotool wmctrl` — **X11 only**; on Linux Mint Cinnamon (X11 by default) it works out of the box, and it silently no-ops elsewhere.

These instructions assume a GNOME/Cinnamon desktop with `gnome-terminal` or any terminal emulator that supports desktop notifications. The statusline works in any terminal. The notifications require a notification daemon (standard on GNOME/Cinnamon/KDE).

---

## Step 1 — Create `~/.claude/statusline-command.sh`

This script is called by Claude Code on each statusline refresh. It receives a JSON object on stdin and outputs a formatted string to display in the status bar.

Create the file at `~/.claude/statusline-command.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Claude Code statusLine command

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // ""')
rate_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // ""')

# status label: yellow while busy, green when idle
state=$(cat "$HOME/.claude/processing_state" 2>/dev/null || echo "idle")
if [ "$state" = "busy" ]; then
  printf '\033[01;33m[processing...]\033[00m '
else
  printf '\033[01;32m[ready/next?]\033[00m '
fi

# username:dirname
printf '\033[01;32m%s\033[00m:\033[01;34m%s\033[00m' "$(whoami)" "$(basename "$cwd")"

# model name (shortened: "Claude Sonnet 4.6" -> "sonnet-4.6")
if [ -n "$model" ]; then
  short=$(echo "$model" | sed 's/[Cc]laude //;s/ /-/g' | tr '[:upper:]' '[:lower:]')
  printf ' \033[00;33m%s\033[00m' "$short"
fi

# 5-hour session rate limit usage (traffic-light colour)
if [ -n "$rate_pct" ]; then
  pct_int=$(printf '%.0f' "$rate_pct" 2>/dev/null || echo 0)
  if [ "$pct_int" -ge 80 ]; then
    color='\033[01;31m'
  elif [ "$pct_int" -ge 50 ]; then
    color='\033[01;33m'
  else
    color='\033[01;32m'
  fi
  printf " ${color}session (5h): %.0f%%\033[00m" "$rate_pct"
fi

# context window usage (traffic-light colour)
if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct" 2>/dev/null || echo 0)
  if [ "$pct_int" -ge 80 ]; then
    color='\033[01;31m'
  elif [ "$pct_int" -ge 50 ]; then
    color='\033[01;33m'
  else
    color='\033[01;32m'
  fi
  printf " ${color}context use at: %.0f%%\033[00m" "$used_pct"
fi
```

Make it executable:

```bash
chmod +x ~/.claude/statusline-command.sh
```

**What you will see in the statusline:**

```
[ready/next?]  dpc:my-project  sonnet-4.6  Session (5h): 21%. Context use at: 38%.
```

While Claude is processing:

```
[processing...]  dpc:my-project  sonnet-4.6  Session (5h): 21%. Context use at: 38%.
```

Percentages turn yellow at 50% and red at 80%.

**Note on `[processing...]` reliability:** The statusline is a pull mechanism — Claude Code only calls it when it redraws the UI, which happens during tool calls (file reads, edits, bash commands). For responses that involve tools (ingests, queries, lints), `[processing...]` shows reliably. For very short pure-text responses, the round-trip may complete before the statusline refreshes, so it may go directly to `[ready/next?]`. The done-signal notification (Step 2) is the reliable signal for all response types.

---

## Step 2 — Create `~/.claude/title-hook.sh`

This script is called by Claude Code hooks. It maintains a state file that the statusline reads, and sends a silent desktop notification when Claude finishes.

Create the file at `~/.claude/title-hook.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Claude Code processing state — drives the statusline label, desktop
# notifications, and (X11) returning focus to the terminal Claude runs in.
STATE_FILE="$HOME/.claude/processing_state"
WIN_FILE="$HOME/.claude/claude_window_id"
PENDING_FILE="$HOME/.claude/notify_pending"
# Grace period before a "needs you" popup appears, in seconds. Override live with
# e.g. CLAUDE_NOTIFY_DELAY=15 in the environment; default is 30.
NOTIFY_DELAY="${CLAUDE_NOTIFY_DELAY:-30}"

refocus() {  # raise the terminal the current prompt came from (X11 only; silent no-op otherwise)
  if [ "$XDG_SESSION_TYPE" = "x11" ] && [ -s "$WIN_FILE" ] && command -v xdotool >/dev/null 2>&1; then
    xdotool windowactivate "$(cat "$WIN_FILE")" 2>/dev/null
  fi
}

terminal_focused() {  # exit 0 (true) ONLY when Claude's terminal is the active X11 window.
  # If we can't tell (no X11 / no xdotool / no saved window) we return false, so the
  # popup still fires — better to nudge than to go silent on a system we can't read.
  [ "$XDG_SESSION_TYPE" = "x11" ] && command -v xdotool >/dev/null 2>&1 || return 1
  [ -s "$WIN_FILE" ] || return 1
  local active saved
  active=$(xdotool getactivewindow 2>/dev/null) || return 1
  saved=$(cat "$WIN_FILE" 2>/dev/null)
  [ -n "$saved" ] && [ "$active" = "$saved" ]
}

clear_pending() { rm -f "$PENDING_FILE"; }

case "$1" in
  start)
    echo "busy" > "$STATE_FILE"
    clear_pending   # a fresh prompt means any earlier "needs you" is moot
    # Remember this terminal's window so stop/notify can return focus to it.
    if [ "$XDG_SESSION_TYPE" = "x11" ] && command -v xdotool >/dev/null 2>&1; then
      xdotool getactivewindow > "$WIN_FILE" 2>/dev/null
    fi
    ;;
  stop)
    echo "idle" > "$STATE_FILE"
    clear_pending   # turn ended; cancel any pending "needs you"
    notify-send -u normal -t 5000 -i dialog-information -h int:suppress-sound:1 \
      "Claude" "✓ Done — ready for input" 2>/dev/null
    refocus
    ;;
  clear)
    # Work resumed (e.g. you granted a permission and a tool ran) — cancel any
    # pending "needs you" so it doesn't pop 25 seconds after you've moved on.
    clear_pending
    ;;
  notify)
    # Claude is blocked waiting on YOU — a tool-permission decision, or idle input.
    # Don't interrupt immediately. Record the request and hand off to the detached
    # `_fire` worker, which waits NOTIFY_DELAY seconds and only pops if (a) you still
    # haven't dealt with it AND (b) the terminal is NOT your focused window — i.e.
    # you've wandered off. Heads-down at the terminal => no interruption.
    nonce="$$-$(date +%s%N)"
    echo "$nonce" > "$PENDING_FILE"
    if command -v setsid >/dev/null 2>&1; then
      setsid bash "$0" _fire "$nonce" >/dev/null 2>&1 < /dev/null &
    else
      nohup bash "$0" _fire "$nonce" >/dev/null 2>&1 &
    fi
    ;;
  _fire)
    # Deferred-popup worker, spawned detached by `notify`. Not wired to any hook.
    nonce="$2"
    sleep "$NOTIFY_DELAY"
    [ "$(cat "$PENDING_FILE" 2>/dev/null)" = "$nonce" ] || exit 0  # handled or superseded → stay silent
    terminal_focused && exit 0                                     # you're at the terminal → don't nag
    clear_pending
    notify-send -u normal -t 5000 -i dialog-question -h int:suppress-sound:1 \
      "Claude — needs you" "⏳ Waiting for a decision / input" 2>/dev/null
    refocus
    ;;
esac
```

Make it executable:

```bash
chmod +x ~/.claude/title-hook.sh
```

**What this does:**
- **`start`** (you submit a prompt): writes `busy` to `~/.claude/processing_state` (statusline reads this); on X11, records this terminal's window ID for focus-return; clears any pending "needs you".
- **`stop`** (Claude finishes): writes `idle`, fires a silent "✓ Done — ready for input" popup (5s), returns focus to the terminal, and clears any pending "needs you".
- **`notify`** (Claude is blocked waiting on you — a tool-permission decision or idle input): does **not** pop immediately. It records the request and spawns a detached `_fire` worker that waits `NOTIFY_DELAY` seconds (default 30) and only then pops a 5s "⏳ needs you" popup **if** you still haven't dealt with it **and** the terminal isn't your focused window. See the Appendix for the rationale.
- **`clear`** (wired to `PostToolUse`): work resumed — cancels any pending "needs you" so it can't pop after you've already moved on.
- **`_fire`** (internal; spawned by `notify`, not wired to a hook): the deferred-popup worker described above.
- Focus-return and focus-detection are X11-only; both degrade to a safe fallback elsewhere — see the Appendix.

---

## Step 3 — Update `~/.claude/settings.json`

Add or merge the following into `~/.claude/settings.json`. If the file already exists, preserve any existing keys and add the new ones.

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /home/YOUR_USERNAME/.claude/statusline-command.sh"
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /home/YOUR_USERNAME/.claude/title-hook.sh start"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /home/YOUR_USERNAME/.claude/title-hook.sh stop"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /home/YOUR_USERNAME/.claude/title-hook.sh notify"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /home/YOUR_USERNAME/.claude/title-hook.sh clear"
          }
        ]
      }
    ]
  }
}
```

**Important:** Replace `YOUR_USERNAME` with the actual username (run `whoami` to confirm). Use the full absolute path — do not use `~` or `$HOME` in the command strings. The `PostToolUse` → `clear` hook is what cancels a deferred "needs you" once you've granted a permission and work resumes; without it a popup could fire ~30s after you'd already moved on.

---

## Step 4 — Verify

No restart required. Changes take effect immediately.

1. **Statusline**: look at the bottom status bar in Claude Code — it should show `[ready/next?] username:dirname model session (5h): N% context use at: N%`.
2. **Processing label**: send a message that requires tool use (e.g. ask Claude to read a file). The statusline should briefly show `[processing...]` in yellow.
3. **Done notification**: when the response finishes, a silent "✓ Done — ready for input" popup should appear for 5 seconds.

If the statusline shows nothing or errors, check that `jq` is installed and the path in `settings.json` is correct.

If notifications do not appear, check that `notify-send` is installed and a notification daemon is running (`ps aux | grep notification`).

---

## Notes

- The `suppress-sound` hint uses `int:suppress-sound:1` (not `boolean`). Some versions of `notify-send` only support `int`, `double`, `string`, and `byte` hint types.
- The statusline script reads its JSON input once on each call. It is safe to add or remove fields without breaking the rest of the output — missing fields fall back to empty string via `// ""` in jq.
- The `rate_limits.five_hour` field is only populated after at least one API call in the session. It will be blank on the very first statusline refresh.
- Traffic-light thresholds (50% yellow, 80% red) can be adjusted by editing the `pct_int` comparisons in `statusline-command.sh`.
- The state file (`~/.claude/processing_state`) is created automatically on first use. It defaults to `idle` if missing.

---

## Appendix — Terminal Focus-Return & "Needs You" Notification

Two additions layered on the base setup above, both wired through `title-hook.sh` (Step 2) and `settings.json` (Step 3):

1. **Focus-return** — when Claude finishes *or* a deferred "needs you" finally fires, the terminal it runs in is raised back to the foreground, so you don't have to hunt for it. It records the terminal's window ID on `start` (`xdotool getactivewindow`) and re-activates it on `stop`/`_fire` (`xdotool windowactivate`).
2. **"Needs you" notification — deferred and focus-gated.** When Claude blocks on a decision — a **tool-permission prompt**, or idle input — you *don't* get an immediate popup. Instead the `Notification` hook records the request and a detached worker waits `NOTIFY_DELAY` seconds (default **30**), then pops a 5-second "⏳ needs you" popup **only if both** of these still hold:
   - **you haven't dealt with it** — the request wasn't cleared by you responding (`start`), the turn ending (`stop`), or work resuming after a granted permission (`clear`, wired to `PostToolUse`); **and**
   - **the terminal is not your focused window** — checked via `xdotool getactivewindow` vs. the saved terminal window ID.

   **Why deferred + focus-gated (the UX rationale):** an immediate popup is an *interruption* when you're heads-down at the terminal mid-thought — you can see the prompt yourself, you just need a moment. But when you've wandered off to a browser, the nudge is genuinely useful. Those two cases are distinguished by **where your attention is**, i.e. *is the terminal focused* — **not** by whether you're idle. A naive "user is idle?" test (`xprintidle`) gets the wandered-off case exactly backwards: you're actively browsing, so not idle, so it would wrongly stay silent. Focus is the correct signal. The 30s grace period then means a quick decision you handle in a few seconds never pops at all.

   This still closes the original gap it was built for: a permission prompt pauses Claude *mid-turn*, so the `Stop` hook never fires for it — without a `Notification`-hook signal you'd get **nothing**. Wired via Claude Code's **`Notification` hook** → `title-hook.sh notify` (defer), with **`PostToolUse`** → `title-hook.sh clear` (cancel-on-resume). Tune the delay live with `CLAUDE_NOTIFY_DELAY=<seconds>` in the environment.

**Requirements — X11 only:**
- `sudo apt install xdotool wmctrl libnotify-bin`
- Works on **Linux Mint Cinnamon**, which defaults to **X11**, so focus-return works out of the box. Check any host with `echo $XDG_SESSION_TYPE` (should print `x11`).
- On **Wayland**, external window activation is blocked for security; focus-return silently no-ops (the notifications still fire). Getting it there needs a Shell extension exposing a window-activate DBus method, called via `gdbus`.
- If `xdotool windowactivate` only *flashes the taskbar* (focus-stealing prevention), swap that line in `title-hook.sh` for `wmctrl -ia "$(cat "$WIN_FILE")"`.

**Setting this up on a new Linux Mint host** — this config is **user-global**: it lives in `~/.claude/` and applies to *every* Claude Code project on the host; it does **not** travel with any project repo, so you must recreate it per machine:
1. `sudo apt install jq libnotify-bin xdotool wmctrl`
2. Recreate `~/.claude/statusline-command.sh` and `~/.claude/title-hook.sh` (Steps 1–2), then `chmod +x` both.
3. Merge the `statusLine` + `UserPromptSubmit`/`Stop`/`Notification`/`PostToolUse` hooks into `~/.claude/settings.json` (Step 3), replacing `YOUR_USERNAME` (run `whoami`).

**Verify:** trigger a tool-permission prompt (or let the prompt idle ~60s), then **click away to another window** and wait for the delay to elapse → a 5-second "⏳ needs you" popup appears and the terminal jumps to the foreground. Repeat but **stay in the terminal** → no popup (focus-gated). Tip: set `CLAUDE_NOTIFY_DELAY=3` while testing so you don't wait the full 30s. On completion → the transient "✓ Done" popup + focus-return.
