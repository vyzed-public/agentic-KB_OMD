#!/usr/bin/env bash
# test-localizer.sh — prove attachment-localize.py actually localizes remote image
# embeds AND fails loud (never silent) on trouble. Stands up a throwaway localhost
# HTTP server serving a real PNG + a zero-byte PNG, then drives the real shipped
# script end-to-end. Local only; needs python3 + bash. No Obsidian, no network.
# Run: bash 1_agentic_config/tests/test-localizer.sh
set -u
FW=$(cd "$(dirname "$0")/../.." && pwd)
LOC="$FW/1_agentic_config/scripts/attachment-localize.py"
pass=0; fail=0
check(){ local desc="$1" ok="$2"
  if [ "$ok" = "1" ]; then printf '  PASS  %s\n' "$desc"; pass=$((pass+1))
  else printf '  FAIL  %s\n' "$desc"; fail=$((fail+1)); fi; }

R=$(mktemp -d); SRV="$R/srv"; mkdir -p "$SRV"
# a real 1x1 PNG, and a deliberately zero-byte file (silent-failure vector)
python3 -c 'import base64,sys;open(sys.argv[1],"wb").write(base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC"))' "$SRV/real.png"
: > "$SRV/empty.png"

PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SRV" >/dev/null 2>&1 &
SRV_PID=$!
trap 'kill "$SRV_PID" 2>/dev/null; rm -rf "$R"' EXIT
# wait for the server to accept connections
for _ in $(seq 1 50); do
  python3 -c "import urllib.request,sys;urllib.request.urlopen('http://127.0.0.1:$PORT/real.png',timeout=1)" 2>/dev/null && break
  sleep 0.1
done

BASE="http://127.0.0.1:$PORT"
echo "=== attachment-localize.py — end-to-end ==="

# 1. HAPPY PATH — remote embed with alt text
N="$R/note1.md"; A="$R/assets1"
printf '# Note\n\ntext ![diagram](%s/real.png) more\n' "$BASE" > "$N"
python3 "$LOC" "$N" "$A" >/dev/null 2>&1; rc=$?
check "happy path exits 0"                 "$([ $rc -eq 0 ] && echo 1)"
check "asset file downloaded, non-empty"   "$([ -n "$(find "$A" -name '*.png' -size +0c 2>/dev/null)" ] && echo 1)"
check "note rewritten to ![[...]] wikilink" "$(grep -q '!\[\[real-[0-9a-f]*\.png|diagram\]\]' "$N" && echo 1)"
check "no remote ](http embed remains"     "$(! grep -q '](http' "$N" && echo 1)"

# 2. NO EMBEDS — nothing to do, must succeed and not touch the note
N="$R/note2.md"; A="$R/assets2"
printf '# Plain\n\nno images here.\n' > "$N"; before=$(cat "$N")
python3 "$LOC" "$N" "$A" >/dev/null 2>&1; rc=$?
check "no-embeds note exits 0"             "$([ $rc -eq 0 ] && echo 1)"
check "no-embeds note left byte-identical" "$([ "$(cat "$N")" = "$before" ] && echo 1)"

# 3. DRY-RUN — reports but writes nothing (note unchanged, no asset dir populated)
N="$R/note3.md"; A="$R/assets3"
printf '# Dry\n\n![x](%s/real.png)\n' "$BASE" > "$N"; before=$(cat "$N")
python3 "$LOC" "$N" "$A" --dry-run >/dev/null 2>&1; rc=$?
check "dry-run exits 0"                     "$([ $rc -eq 0 ] && echo 1)"
check "dry-run leaves note unchanged"      "$([ "$(cat "$N")" = "$before" ] && echo 1)"
check "dry-run writes no asset file"       "$([ -z "$(find "$A" -type f 2>/dev/null)" ] && echo 1)"

# 4. DEAD URL (404) — must FAIL LOUD (exit 2) and leave the note UNCHANGED
N="$R/note4.md"; A="$R/assets4"
printf '# Dead\n\n![y](%s/does-not-exist.png)\n' "$BASE" > "$N"; before=$(cat "$N")
python3 "$LOC" "$N" "$A" >/dev/null 2>&1; rc=$?
check "404 fetch exits 2 (fail loud)"      "$([ $rc -eq 2 ] && echo 1)"
check "404 leaves note UNCHANGED"          "$([ "$(cat "$N")" = "$before" ] && echo 1)"

# 5. ZERO-BYTE download — the silent-failure vector; must exit 2, note UNCHANGED
N="$R/note5.md"; A="$R/assets5"
printf '# Empty\n\n![z](%s/empty.png)\n' "$BASE" > "$N"; before=$(cat "$N")
python3 "$LOC" "$N" "$A" >/dev/null 2>&1; rc=$?
check "zero-byte download exits 2"         "$([ $rc -eq 2 ] && echo 1)"
check "zero-byte leaves note UNCHANGED"    "$([ "$(cat "$N")" = "$before" ] && echo 1)"

echo ""; echo "localizer: $pass passed, $fail failed."
[ $fail -eq 0 ]
