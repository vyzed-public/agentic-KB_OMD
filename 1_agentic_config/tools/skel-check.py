#!/usr/bin/env python3
# skel-check.py [DIR]
# Scan a vault/skeleton for dangling [[wikilinks]]. DIR defaults to CWD.
# Links resolve by basename (case-insensitive) or vault-relative path; code-span
# links are ignored. Exit 0 = clean, 1 = dangling links found.
import re, os, glob, sys
D = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.getcwd()
names, paths = set(), set()
for p in glob.glob(f'{D}/**/*.md', recursive=True):
    names.add(os.path.splitext(os.path.basename(p))[0].lower())
    paths.add(os.path.splitext(os.path.relpath(p, D))[0].lower())
link_re = re.compile(r'\[\[([^\]]+?)\]\]')
def norm(x): return x.strip().split('|')[0].split('#')[0].strip().lower()
def resolves(x): n = norm(x); return n in names or n in paths
def strip_code(b):
    b = re.sub(r'```.*?```', '', b, flags=re.S)
    return re.sub(r'`[^`]*`', '', b)
def split(t):
    m = re.match(r'^---\n(.*?)\n---\n?(.*)$', t, re.S)
    return (m.group(1), m.group(2)) if m else ("", t)
bad = 0; n = 0
for p in glob.glob(f'{D}/**/*.md', recursive=True):
    n += 1
    fm, body = split(open(p).read())
    for L in link_re.findall(fm) + link_re.findall(strip_code(body)):
        if not resolves(L):
            print(f"DANGLING in {os.path.relpath(p, D)}: [[{L}]]"); bad += 1
print(f"scanned {n} md files; {'0 dangling — clean' if bad == 0 else str(bad) + ' dangling'}")
sys.exit(1 if bad else 0)
