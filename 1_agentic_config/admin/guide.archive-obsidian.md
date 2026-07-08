# Guide — Archiving Obsidian (version preservation / business continuity)

## Why this exists

This knowledge base **depends on Obsidian**. Obsidian is **open-*data*** (your notes are plain Markdown files you fully own and can read with anything) but it is **not open-*source*** — the app ships under a proprietary EULA (`LicenseRef-proprietary`, https://obsidian.md/eula). So if Obsidian ever disappears, changes its terms, or stops offering old downloads, we want a **local, known-good copy of the exact version we run**, so the whole system keeps working indefinitely.

Your *notes* are already safe — plain Markdown, git-backed. **This guide preserves the reader/editor app**, not the data.

## Where the artifacts go

Each archival round lives in its own dated, method-grouped folder under `~/my/installs/`:

```
~/my/installs/obsidian.multiple-methods.c-2026-Q3/
```

Naming convention:
- **`obsidian`** — the app being archived.
- **`multiple-methods`** — this folder holds *several* install formats side by side (AppImage + `.deb` + Flatpak bundle), so you can restore whichever suits the future machine.
- **`c-2026-Q3`** — "current as of 2026-Q3" (same time-scope tag used elsewhere, e.g. `c-2026-Q2`). Each time you re-archive a newer Obsidian, make a **new** dated folder (e.g. `obsidian.multiple-methods.c-2026-Q4`) rather than overwriting this one.

The command blocks below set `$ARCHIVE` to this folder once — **run them in the same shell session**, or re-run the first line to re-set it:

```bash
ARCHIVE=~/my/installs/obsidian.multiple-methods.c-2026-Q3
mkdir -p "$ARCHIVE"
```

---

## What we're preserving (this host — recorded 2026-07-06)

| Field | Value |
|---|---|
| App | Obsidian (`md.obsidian.Obsidian`) |
| **Version** | **1.12.7** |
| Flatpak commit | `<paste your key locally; NEVER commit a real key to a shared repo>` |
| Build date | 2026-03-23 |
| Runtime dep | `org.freedesktop.Platform` **25.08** |
| Install type | Flatpak (system, from flathub) — 614.5 MB installed |
| License | proprietary (obsidian.md/eula) |

Re-snapshot this table anytime with: `flatpak info md.obsidian.Obsidian`

---

## Three artifacts, three levels of insurance

Grab as many as you like — they're complementary:

1. **`.AppImage` — the strongest "back pocket" insurance.** A single self-contained file: no install, no dependencies, runs on any Linux. If Obsidian ever truly vanishes, this one file still launches. **Recommended as the primary archive.**
2. **`.deb` — native package** of the same version (Debian/Ubuntu). Cleanest if you want a real system install rather than a Flatpak.
3. **Flatpak bundle — exact replica** of your *current* install. Reproduces this setup byte-for-byte, but for a fully offline reinstall it also needs its runtime bundled (below).

### Artifacts 1 & 2 — native downloads (recommended)

Pulled straight from Obsidian's public release repo, matching version `1.12.7`:

```bash
cd "$ARCHIVE"
curl -LO https://github.com/obsidianmd/obsidian-releases/releases/download/v1.12.7/Obsidian-1.12.7.AppImage
curl -LO https://github.com/obsidianmd/obsidian-releases/releases/download/v1.12.7/obsidian_1.12.7_amd64.deb
chmod +x Obsidian-1.12.7.AppImage
```

**Restore later:**
- AppImage — nothing to install: `"$ARCHIVE"/Obsidian-1.12.7.AppImage`
- .deb — `sudo apt install "$ARCHIVE"/obsidian_1.12.7_amd64.deb` (or `sudo dpkg -i …`)

### Artifact 3 — Flatpak bundle (reproduce *this* install)

Export the installed app — and its runtime, which the app bundle needs to install offline — to single files:

```bash
# the app itself (may need sudo to read the system repo)
flatpak build-bundle /var/lib/flatpak/repo \
  "$ARCHIVE"/md.obsidian.Obsidian-1.12.7.flatpak  md.obsidian.Obsidian stable

# its runtime — required to install the app bundle without network
flatpak build-bundle --runtime /var/lib/flatpak/repo \
  "$ARCHIVE"/org.freedesktop.Platform-25.08.flatpak  org.freedesktop.Platform 25.08
```

**Restore later** (runtime first, then app):
```bash
flatpak install --bundle "$ARCHIVE"/org.freedesktop.Platform-25.08.flatpak
flatpak install --bundle "$ARCHIVE"/md.obsidian.Obsidian-1.12.7.flatpak
```

> **Caveat:** the base-runtime bundle covers the essentials, but some runtime *extensions* (GL drivers, codecs) can still be pulled from Flathub at install time. For a **guaranteed** offline copy, rely on the **AppImage** (artifact 1) — it's fully self-contained.

---

## Record checksums (so you can trust the archive years from now)

After downloading/exporting, capture hashes next to the files:

```bash
cd "$ARCHIVE"
sha256sum Obsidian-1.12.7.AppImage obsidian_1.12.7_amd64.deb \
          md.obsidian.Obsidian-1.12.7.flatpak org.freedesktop.Platform-25.08.flatpak \
  2>/dev/null | tee obsidian-1.12.7.sha256
```

---

## Maintenance

When you upgrade Obsidian, **run this guide again for the new version** in a **new dated folder** (`~/my/installs/obsidian.multiple-methods.c-<year>-Q<n>/`), and keep at least **current + previous**. Update the version table above (or add a new dated row) so the archive stays self-documenting.

---

_The notes are plain Markdown and git-backed; this guide preserves the app that reads them. And if Obsidian ever really does go away — that's the day someone finally writes the open-source Rust rewrite. Working title: **Ferrite**._
