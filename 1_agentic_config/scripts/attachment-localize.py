#!/usr/bin/env python3
"""attachment-localize.py — headless replacement for Obsidian's "Download
attachments" modal (which no API can bypass; see HISTORY.explored-and-retired).

Parses a markdown note for remote image embeds `![alt](http...)`, downloads each
into an assets dir under a BASH- and wikilink-safe filename, and rewrites the
embed to a local Obsidian `![[basename|alt]]` wikilink. No Obsidian, no MCP, no
modal — just fetch + rewrite.

FAILS LOUD, NEVER SILENT (this is the whole point — a silent no-op is the bug we
are guarding against): any fetch error, HTTP error, zero-byte download, or embed
left un-localized makes the script exit NON-ZERO and print exactly what failed.
The note is only rewritten if EVERY embed localized cleanly. On any failure the
note is left untouched so the caller can stop before filing it without its images.

Usage:
  attachment-localize.py <note.md> <assets-dir> [--dry-run]

Exit codes:
  0  all remote image embeds localized (or none present); note rewritten
  2  one or more embeds failed to download / verify; note UNCHANGED
  1  usage / IO error
"""
import sys, os, re, hashlib, urllib.request, urllib.parse, mimetypes

IMG_RE = re.compile(r'!\[([^\]]*)\]\((https?://[^)\s]+)\)')
EXT_OK = {'.png', '.gif', '.webp', '.jpg', '.jpeg', '.svg', '.bmp', '.avif'}


def safe_name(url, content_type):
    """Bash- and wikilink-safe, readable, deduped by an 8-char url hash."""
    path = urllib.parse.urlparse(url).path
    root, ext = os.path.splitext(os.path.basename(path))
    if ext.lower() not in EXT_OK:
        ext = mimetypes.guess_extension((content_type or '').split(';')[0].strip()) or '.img'
    root = re.sub(r'[^A-Za-z0-9._-]', '-', root).strip('-.') or 'img'
    digest = hashlib.sha1(url.encode()).hexdigest()[:8]
    return f'{root[:40]}-{digest}{ext.lower()}'


def fetch(url):
    """Return (bytes, content_type). Raises on any HTTP/network error."""
    req = urllib.request.Request(url, headers={'User-Agent': 'obsidian-ingest/1.0'})
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read(), r.headers.get('Content-Type', '')


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    dry = '--dry-run' in sys.argv
    if len(args) != 2:
        print('usage: attachment-localize.py <note.md> <assets-dir> [--dry-run]',
              file=sys.stderr)
        return 1
    note, assets = args
    try:
        text = open(note, encoding='utf-8').read()
    except OSError as e:
        print(f'ERROR: cannot read note: {e}', file=sys.stderr)
        return 1

    matches = list(IMG_RE.finditer(text))
    if not matches:
        print('no remote image embeds found — nothing to localize')
        return 0

    if not dry:
        os.makedirs(assets, exist_ok=True)

    new = text
    failures = []
    localized = 0
    for m in matches:
        alt, url = m.group(1), m.group(2)
        try:
            data, ctype = fetch(url)
        except Exception as e:                      # network, HTTP 4xx/5xx, timeout
            failures.append(f'{url}  ->  FETCH FAILED: {e}')
            continue
        if not data:                                # zero-byte = silent failure vector
            failures.append(f'{url}  ->  DOWNLOADED 0 BYTES')
            continue
        fn = safe_name(url, ctype)
        dest = os.path.join(assets, fn)
        if not dry:
            try:
                with open(dest, 'wb') as fh:
                    fh.write(data)
                if os.path.getsize(dest) != len(data):   # verify what landed on disk
                    failures.append(f'{url}  ->  WRITE VERIFY FAILED ({dest})')
                    continue
            except OSError as e:
                failures.append(f'{url}  ->  WRITE FAILED: {e}')
                continue
        embed = f'![[{fn}|{alt}]]' if alt else f'![[{fn}]]'
        new = new.replace(m.group(0), embed)
        localized += 1
        print(f'{"DRY " if dry else ""}{len(data):>8}B  {url[:58]:58}  ->  {embed}')

    # Post-condition: no remote image embed may survive in the rewritten text.
    leftover = IMG_RE.findall(new)
    if failures or leftover:
        for f in failures:
            print(f'  ✗ {f}', file=sys.stderr)
        if leftover:
            print(f'  ✗ {len(leftover)} remote embed(s) still present after rewrite',
                  file=sys.stderr)
        print(f'\nFAILED: {len(matches) - localized}/{len(matches)} embed(s) not '
              f'localized; note LEFT UNCHANGED. Do NOT file this note.', file=sys.stderr)
        return 2

    if not dry:
        with open(note, 'w', encoding='utf-8') as fh:
            fh.write(new)
    print(f'\nOK: {localized}/{len(matches)} embed(s) localized; '
          f'note {"unchanged (dry-run)" if dry else "rewritten"}.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
