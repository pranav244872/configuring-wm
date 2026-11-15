# WordCraft (Word alternative)

Installed 2026-11-10 from the AUR as **`wordcraft-bin`** (prebuilt release
tarball). It is the ArtCraft team's clean-room reimplementation of Microsoft
Word in pure Rust: egui on the GPU, no Electron, reads/writes `.docx` and also
`.odt`, `.rtf`, `.html`, `.md`, `.tex`, `.txt`, imports legacy `.doc`.

Back to [notes index](README.md) - [docs index](../README.md)

## How it finds fonts — not fontconfig

This is the whole reason the font choice differs from every other app here:

- `ldd /usr/bin/wordcraft` shows **no `libfontconfig`**, and the binary contains
  no fontconfig strings. It carries its own font database and scans these
  directories directly:
  `/usr/share/fonts`, `/usr/local/share/fonts`, `~/.fonts`,
  `~/.local/share/fonts` (plus `/run/host/{fonts,local-fonts,user-fonts,user-fonts-legacy}`
  for the Flatpak build).
- **Fontconfig aliases are therefore ignored.** A document that says `Calibri`
  does not resolve to Carlito through fontconfig; WordCraft only uses a
  substitute from its own table when the family is genuinely missing.
- So a font is "installed" for WordCraft when its file sits in one of the
  scanned directories — `fc-cache` is irrelevant to it (still run it for the
  rest of the system).

## Built-in substitute table (verified in the binary)

`Arial → Liberation Sans → Helvetica → Arimo`, `Calibri → Carlito`,
`Cambria → Caladea`, `Times New Roman → Tinos`,
`Courier New → Liberation Mono → Cousine`,
`Palatino Linotype / Book Antiqua → URW Palladio L`.

The substitutes are metric-compatible, so a document keeps its pagination;
only the glyph shapes differ. This is why `ttf-carlito`/`ttf-caladea` are a
valid fallback — but with the real Microsoft fonts installed they are never
used and must not be installed as well (duplicate families for no gain).

## Font commands (also in the UI, Home › Font)

| Command | What |
|---|---|
| `font.missing` | what the current view needs but has not: `{"missing":[{"font","shownAs","metricCompatible"}]}` |
| `font.add` | add one TTF/OTF/TTC/WOFF/WOFF2 file, kept by the app — no system install |
| `font.remove` | drop an added family |
| `font.list` | added families (`all: true` for every available family) |
| `font.loadSystem` | re-scan system font directories |

The status bar shows `{n} fonts not installed` / "Shown in substitute fonts"
while a document references a family it cannot find — the same data as
`font.missing`.

## Microsoft fonts

Two AUR packages, ~66 MB once, installed into `/usr/share/fonts/TTF`:

| Package | Size | Families |
|---|---|---|
| `ttf-ms-fonts` (2.0-12) | ~6 MB (corefonts `.exe` from SourceForge) | Arial, Arial Black, Times New Roman, Courier New, Georgia, Verdana, Trebuchet MS, Comic Sans MS, Impact, Andale Mono, Webdings |
| `ttf-vista-fonts` (1-12) | 60 MB (PowerPoint Viewer 2007 cab from archive.org; `cabextract` + `fontforge` converts `cambria.ttc`) | Calibri, Cambria + Cambria Math, Candara, Consolas, Constantia, Corbel, Meiryo |

**Not `ttf-ms-win11-auto`.** It tries to fetch the fonts over HTTP out of a
Windows 11 ISO and, when that fails, downloads the **full 5.01 GB ISO** and
extracts `install.wim` — observed on 2026-11-15 (aborted after 1.4 GB). With
paru's `CleanAfter` the source cache is deleted, so an update can repeat it.

No Segoe UI: `fc-match "Segoe UI"` still resolves to Adwaita Sans. Word
documents rarely reference it; if one does, `ttf-ms-aptos-core` (~6 MB, Aptos +
core fonts) is the only small addition.

Duplicates: no family+style is installed twice
(`fc-list --format '%{family}|%{style}' | sort | uniq -d` is empty).
`ttf-liberation` stays — `chromium`, `firefox` and `steam` require it — and its
families never collide with the Microsoft names.

## Verify

```bash
fc-match Calibri; fc-match Arial     # must name calibri.ttf / Arial.TTF, not Liberation
# WordCraft's own view. `wordcraft-cli run` prints no results; use its MCP server:
wordcraft-cli mcp   # initialize -> new_document -> type_text -> select_text
                    # -> execute format.font {"name":"Calibri"} -> execute font.missing
```

`font.missing` returned `{"missing": []}` for Calibri after the install; the
control run with `"NoSuchFont ZZ"` returned
`{"missing":[{"font":"NoSuchFont ZZ","metricCompatible":false,"shownAs":["Arial"]}]}`,
so the probe really checks resolution.

## Files

| Path | What |
|---|---|
| `/usr/bin/wordcraft`, `/usr/bin/wordcraft-cli` | desktop app, headless converter/MCP |
| `~/.config/wordcraft/logs/wordcraft.log` | app log (rotated to `.1`, `.2`) |
| `~/.config/wordcraft/ui.json` | ribbon/window/recent state |
