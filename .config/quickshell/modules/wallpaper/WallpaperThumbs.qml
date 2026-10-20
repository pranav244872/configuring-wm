// Wallpaper thumbnails: an ffmpeg-generated JPEG cache for the picker strip.
//
// PNG decode is not size-scalable, so the carousel's `sourceSize` still decoded
// the whole 4 MB file: 142-308 ms per slide on this machine (measured
// 2026-10-19), which is exactly the stall browsing hit. A 448x252 JPEG decodes
// in a few ms. ImageMagick is not installed, and end-4's generator needs it --
// but ffmpeg is already here for screenshots, so the cache is built with that.
//
// The pass is idempotent: a thumb is only rewritten when the source is newer,
// so it is cheap to re-run whenever the library changes. `thumbs` maps source
// path -> thumb path for the slides to bind to; a source without a thumb (first
// run, still generating) keeps the full image.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.wallpaper

QtObject {
    id: root

    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME")
                                        || (Quickshell.env("HOME") + "/.cache"))
                                       + "/quickshell/wallpaper-thumbs"

    // Slide is 224x126 at DPR 1; build at 2x so a scaled display stays sharp.
    readonly property int thumbWidth: 448
    readonly property int thumbHeight: 252

    // Source path -> thumb path. Replaced wholesale after every pass.
    property var thumbs: ({})
    property bool generating: false
    property bool pending: false

    // md5 of the absolute path names the file, like end-4's freedesktop-style
    // cache; rebuilding only when the source is newer keeps the pass repeatable.
    readonly property string script:
        'd="$1"; o="$2"; mkdir -p "$o"; ' +
        'for f in "$d"/*; do ' +
        '  [ -f "$f" ] || continue; ' +
        '  case "$f" in *.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.webp|*.WEBP|*.avif|*.bmp) ;; *) continue ;; esac; ' +
        '  h=$(printf "%s" "$f" | md5sum | cut -d" " -f1); ' +
        '  t="$o/$h.jpg"; ' +
        '  if [ ! -f "$t" ] || [ "$f" -nt "$t" ]; then ' +
        '    ffmpeg -loglevel error -y -i "$f" -vf "scale=' + root.thumbWidth + ':' + root.thumbHeight +
        ':force_original_aspect_ratio=increase,crop=' + root.thumbWidth + ':' + root.thumbHeight + '" ' +
        '      -frames:v 1 -q:v 6 "$t.tmp.jpg" && mv "$t.tmp.jpg" "$t" || rm -f "$t.tmp.jpg"; ' +
        '  fi; ' +
        '  [ -f "$t" ] && printf "%s\\t%s\\n" "$f" "$t"; ' +
        'done'

    readonly property Process generator: Process {
        command: ["sh", "-c", root.script, "sh", WallpaperService.libraryPath, root.cacheDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                const lines = String(text || "").split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const tab = lines[i].indexOf("\t");
                    if (tab > 0)
                        map[lines[i].slice(0, tab)] = lines[i].slice(tab + 1);
                }
                root.thumbs = map;
            }
        }

        onExited: {
            root.generating = false;
            if (root.pending) {
                root.pending = false;
                root.refresh();
            }
        }

        Component.onCompleted: root.refresh()
    }

    // The library lists asynchronously; the first pass usually runs on an empty
    // folder, so re-run when the count settles.
    readonly property Connections libraryWatch: Connections {
        target: WallpaperService.folder

        function onCountChanged() {
            root.refresh();
        }
    }

    function refresh() {
        if (root.generating) {
            root.pending = true;
            return;
        }
        root.generating = true;
        root.generator.running = true;
    }

    // "" when the source has no thumbnail yet -- the caller falls back to it.
    function pathFor(sourcePath) {
        const thumb = root.thumbs[String(sourcePath)];
        return thumb ? String(thumb) : "";
    }
}
