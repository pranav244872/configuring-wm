// Wallpaper service: the library, the current image, and the state file.
//
// Our shell draws the wallpaper itself (WallpaperBackground.qml, a background
// layer surface) instead of running swww/hyprpaper/awww: one toolkit, no
// daemon. This singleton holds state only -- a 0.3.2 singleton roots on a bare
// QtObject and has no default property, so nothing visual belongs here.
//
// Library: $HOME/Pictures/Wallpapers, flat (the repo's Wallpapers/ that seeds
// it is flat too). quickshell 0.3.2 has no FileSystemModel, so FolderListModel
// does the listing and hands the carousel its filePath role.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.modules

QtObject {
    id: root

    // ---------------------------------------------------------------- library
    // A plain property (not a binding-only readonly) so a probe can point it at
    // an empty directory to exercise the no-library branch.
    property string libraryPath: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    readonly property FolderListModel folder: FolderListModel {
        folder: "file://" + root.libraryPath
        nameFilters: ["*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG",
                      "*.webp", "*.WEBP", "*.avif", "*.bmp"]
        showDirs: false
        showOnlyReadable: true
        caseSensitive: false
        sortField: FolderListModel.Name

        // Adopt only once the listing has finished. Rows arrive while the model
        // is Loading and are not in the configured sort yet, so acting on the
        // first count change can settle on an arbitrary image (it picked
        // 5.png, index 2, on 2026-10-19).
        onStatusChanged: root.adopt()
        onCountChanged: root.adopt()
    }

    function pathAt(index) {
        return index >= 0 && index < root.folder.count
            ? String(root.folder.get(index, "filePath") ?? "") : "";
    }

    function indexOf(path) {
        for (let i = 0; i < root.folder.count; i++)
            if (String(root.folder.get(i, "filePath") ?? "") === path)
                return i;
        return -1;
    }

    // ---------------------------------------------------------------- current
    // Absolute path of the wallpaper on screen; empty until the state file or
    // the library has decided.
    property string current: ""

    readonly property string statePath: (Quickshell.env("XDG_CACHE_HOME")
                                         || (Quickshell.env("HOME") + "/.cache"))
                                        + "/quickshell/wallpaper.json"

    // Set once the state file has been read (or found absent): nothing writes
    // before that, or the startup fallback would clobber the saved choice.
    property bool hydrated: false

    // Benches drive `current` directly; `mock` stops the write-back so a preview
    // never edits the real state file (same convention as the sections' mock).
    property bool mock: false

    // Same shape as the notification service's DND file: one tiny sh read.
    readonly property Process stateLoader: Process {
        command: ["sh", "-c", "cat \"" + root.statePath + "\" 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text || "{}");
                    if (typeof saved.path === "string" && saved.path.length > 0)
                        root.current = saved.path;
                } catch (e) {
                    // No state yet, or a torn write: adopt() picks one.
                }
                root.hydrated = true;
                root.adopt();
            }
        }

        Component.onCompleted: running = true
    }

    readonly property Process stateWriter: Process {}

    // A first run, or a library that moved, still gets a wallpaper instead of a
    // bare desktop: fall back to the first image. A path that is still in the
    // library is never touched, so a saved choice always wins.
    function adopt() {
        if (!root.hydrated || root.folder.status !== FolderListModel.Ready)
            return;
        if (root.folder.count === 0)
            return;
        if (root.current === "" || root.indexOf(root.current) < 0)
            root.current = root.pathAt(0);
    }

    function writeState() {
        // A path *can* contain a quote, so it goes through JSON (which escapes
        // quotes and backslashes) and then inside single quotes for sh.
        const payload = JSON.stringify({ path: root.current }).replace(/'/g, "'\\''");
        root.stateWriter.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"" + root.statePath + "\")\" && "
            + "printf '%s' '" + payload + "' > \"" + root.statePath + "\""];
        root.stateWriter.running = true;
    }

    onCurrentChanged: if (root.hydrated && !root.mock) root.writeState()

    // ------------------------------------------------------------------ apply
    // The background crossfades to it; the change handler writes the state.
    function apply(path) {
        if (path && path.length > 0)
            root.current = path;
    }
}
