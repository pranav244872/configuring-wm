// Wallpaper-derived Material 3 palette for the whole shell.
//
// matugen writes ~/.config/quickshell/colors.json (see ~/.config/matugen/
// config.toml); this singleton reads it, and Theme.qml's `palette` binds to it.
// The semantic `colors` layer above the palette is computed, so a palette
// change re-evaluates every component that consumes Theme.colors -- a wallpaper
// switch recolours bar, OSD, dashboard, picker, notifications, lock card and
// screenshot chrome at once, with no shell restart.
//
// It also owns the generator: WallpaperHost calls sync(path) whenever
// WallpaperService.current changes, and if the palette on disk came from a
// different image, `matugen image <path>` runs and the file is re-read.
//
// State only -- a 0.3.2 singleton roots on a bare QtObject and has no default
// property, so the Processes live in properties (same as WallpaperService).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // -------------------------------------------------------------- palette
    // Parsed colors.json: matugen's Material-3 role names -> "#rrggbb". Null
    // before the first read and while the file does not exist (first run).
    property var m3: null

    // The wallpaper the palette on disk was generated from. matugen writes its
    // own path into the file, so this doubles as "is the palette current?".
    readonly property string image: (root.m3 && typeof root.m3.image === "string")
                                    ? root.m3.image : ""

    readonly property string colorsPath: (Quickshell.env("XDG_CONFIG_HOME")
                                          || (Quickshell.env("HOME") + "/.config"))
                                         + "/quickshell/colors.json"

    // One role, falling back to Theme's built-in value when the palette is
    // unavailable. Theme.palette is the only caller.
    function color(role, fallback) {
        const v = root.m3 ? root.m3[role] : null;
        return (typeof v === "string" && v.length > 0) ? v : fallback;
    }

    // -------------------------------------------------------------- reading
    // One tiny sh read, the same shape as the wallpaper state file's (a missing
    // file is not an error, it just leaves `m3` null).
    readonly property Process loader: Process {
        command: ["sh", "-c", "cat \"" + root.colorsPath + "\" 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text || "{}");
                    root.m3 = (parsed && typeof parsed === "object") ? parsed : null;
                } catch (e) {
                    // Torn write (matugen mid-flight): keep the palette we have
                    // and let the next run replace it.
                }
                root.hydrated = true;
                root.pump();
            }
        }
    }

    // Set once the first read has finished, so a startup sync never regenerates
    // before we know which wallpaper the palette on disk belongs to.
    property bool hydrated: false

    function read() {
        if (!root.loader.running)
            root.loader.running = true;
    }

    // ----------------------------------------------------------- generating
    readonly property Process generator: Process {
        // Re-read either way: on success the palette moved; on failure the file
        // is untouched and pump() backs off for this wallpaper.
        onExited: root.read()
    }

    // The palette we want, and the one we last tried -- a run that fails must
    // not spin, so only a wallpaper change retries.
    property string target: ""
    property string triedFor: ""

    function sync(path) {
        if (!path || path.length === 0)
            return;
        root.target = path;
        root.pump();
    }

    function pump() {
        if (!root.hydrated || root.generator.running || root.target === "")
            return;
        if (root.target === root.image || root.target === root.triedFor)
            return;
        root.triedFor = root.target;
        // scheme-content keeps the wallpaper's own hues; mode, output paths and
        // the per-app reload hooks live in ~/.config/matugen/config.toml.
        root.generator.command = ["matugen", "image", root.target,
                                  "--mode", "dark", "--type", "scheme-content",
                                  "--prefer", "darkness"];
        root.generator.running = true;
    }

    Component.onCompleted: root.read()
}
