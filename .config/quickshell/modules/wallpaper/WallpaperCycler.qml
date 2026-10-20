// Wallpaper cycling: advance the library on a timer, in order or shuffled.
//
// Reference: DMS's WallpaperCyclingService (a scheduler in its server, paused
// while locked or fullscreen, sequential/random, manual next/prev). We have no
// server, so the timer lives in the shell and applies through WallpaperService
// -- the same path a manual pick takes, which means the background crossfade
// and the matugen palette refresh come along for free.
//
// Fullscreen pausing is not implemented: the installed Quickshell exposes no
// toplevel fullscreen state (no Hyprland toplevel type in 0.3.2 here). The timer
// does stop while the session is locked and while the picker is open.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.lock
import qs.modules.wallpaper

QtObject {
    id: root

    property bool enabled: false
    property bool shuffle: false
    property int intervalMinutes: 30
    readonly property var intervalChoices: [5, 10, 15, 30, 60, 120]

    // The picker holds the countdown: the desktop must not change under a sheet
    // someone is browsing.
    property bool suspended: false

    readonly property string configPath: (Quickshell.env("XDG_CACHE_HOME")
                                          || (Quickshell.env("HOME") + "/.cache"))
                                         + "/quickshell/wallpaper-cycling.json"

    // Settings are only written after the file has been read, so the defaults
    // cannot clobber a saved choice (same rule as WallpaperService).
    property bool hydrated: false

    // Benches drive the toggles; mock keeps them out of the real config file.
    property bool mock: false

    // A function, not a bound property: a readonly binding read from inside its
    // own change handler still holds the old value (the toggle left the timer
    // stopped until an unrelated change re-evaluated it).
    function runnable() {
        return root.enabled && root.hydrated && !root.suspended
            && !LockState.locked && WallpaperService.folder.count > 1;
    }

    readonly property Timer timer: Timer {
        repeat: true
        interval: root.intervalMinutes * 60000
        onTriggered: root.next()
    }

    // Any change to the wallpaper restarts the countdown, so a fresh manual pick
    // is not cycled away seconds later.
    readonly property Connections appliedWatch: Connections {
        target: WallpaperService

        function onCurrentChanged() {
            if (root.timer.running)
                root.timer.restart();
        }
    }

    readonly property Connections lockWatch: Connections {
        target: LockState

        function onLockedChanged() {
            root.syncTimer();
        }
    }

    readonly property Connections libraryWatch: Connections {
        target: WallpaperService.folder

        function onCountChanged() {
            root.syncTimer();
        }
    }

    readonly property Process loader: Process {
        command: ["sh", "-c", "cat \"" + root.configPath + "\" 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text || "{}");
                    if (typeof saved.enabled === "boolean")
                        root.enabled = saved.enabled;
                    if (typeof saved.shuffle === "boolean")
                        root.shuffle = saved.shuffle;
                    if (Number.isInteger(saved.intervalMinutes) && saved.intervalMinutes > 0)
                        root.intervalMinutes = saved.intervalMinutes;
                } catch (e) {
                    // No file yet, or a torn write: defaults stand.
                }
                root.hydrated = true;
                root.syncTimer();
            }
        }

        Component.onCompleted: running = true
    }

    readonly property Process writer: Process {}

    function save() {
        if (!root.hydrated || root.mock)
            return;
        const payload = JSON.stringify({
            enabled: root.enabled,
            shuffle: root.shuffle,
            intervalMinutes: root.intervalMinutes
        }).replace(/'/g, "'\\''");
        root.writer.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"" + root.configPath + "\")\" && "
            + "printf '%s' '" + payload + "' > \"" + root.configPath + "\""];
        root.writer.running = true;
    }

    onEnabledChanged: {
        save();
        syncTimer();
    }
    onShuffleChanged: save()
    onIntervalMinutesChanged: save()
    onSuspendedChanged: syncTimer()

    // Explicit start/stop: `running` cannot be bound because restart() would
    // break the binding.
    function syncTimer() {
        if (root.runnable()) {
            if (!root.timer.running)
                root.timer.start();
        } else {
            root.timer.stop();
        }
    }

    // One step through the library. Shuffle keeps the "never the same image"
    // rule DMS uses and falls back to the next slide if the random walk keeps
    // landing on the current one.
    function step(delta) {
        const count = WallpaperService.folder.count;
        if (count < 2)
            return "";
        const current = WallpaperService.indexOf(WallpaperService.current);
        let index = current;
        if (root.shuffle) {
            for (let i = 0; i < 8 && index === current; i++)
                index = Math.floor(Math.random() * count);
            if (index === current)
                index = (Math.max(0, current) + 1) % count;
        } else {
            index = ((current < 0 ? 0 : current) + delta + count) % count;
        }
        const path = WallpaperService.pathAt(index);
        if (!path)
            return "";
        WallpaperService.apply(path);
        return path;
    }

    function next() {
        return root.step(1);
    }

    function prev() {
        return root.step(-1);
    }

    function setEnabled(on) {
        root.enabled = !!on;
    }

    function setShuffle(on) {
        root.shuffle = !!on;
    }

    function setInterval(minutes) {
        root.intervalMinutes = Math.max(1, Math.min(24 * 60, Math.round(Number(minutes) || 30)));
    }

    function nextIntervalPreset() {
        const at = root.intervalChoices.indexOf(root.intervalMinutes);
        root.intervalMinutes = root.intervalChoices[(at + 1) % root.intervalChoices.length];
        return root.intervalMinutes;
    }

    function intervalText() {
        return root.intervalMinutes >= 60 && root.intervalMinutes % 60 === 0
            ? (root.intervalMinutes / 60) + "H"
            : root.intervalMinutes + "M";
    }
}
