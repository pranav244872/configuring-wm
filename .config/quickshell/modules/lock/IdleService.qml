// Idle service: staged inactivity timers with inhibitor support. Normal
// timings: lock 3m, screen off 5m (backlight floor 1%), suspend 10m.
//
// Suppression follows caelestia's IdleMonitors shape: the monitors are
// *disabled* rather than leaning on the compositor, because a bar-surface
// zwp_idle_inhibit goes inactive when a fullscreen window occludes the bar (DMS
// documents the same trap).
//
//   fullscreen  -> every stage held off
//   media       -> blank + suspend held off; the session still locks
//
// Wayland idle inhibitors are still honoured via respectInhibitors, and the
// bar's caffeine toggle remains the manual override.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

Item {
    id: root

    readonly property int lockSecs: 180
    readonly property int offSecs: 300
    readonly property int suspendSecs: 600

    // Any MPRIS player reporting playback (native, no playerctl spawning).
    readonly property bool mediaPlaying: Mpris.players.values.some(p => p.isPlaying)

    // A real fullscreen window on the focused monitor's active workspace.
    // `fullscreen > 1` because 1 is Hyprland's "maximized", not fullscreen.
    //
    // The IPC `fullscreen` event only flips the workspace's hasFullscreen flag;
    // the per-window map is refreshed by other events. So use the flag as the
    // event trigger and pull the map in, otherwise `> 1` is evaluated on stale
    // data (and a maximized window would suppress idle).
    readonly property bool fullscreenOn: {
        const ws = Hyprland.focusedWorkspace;
        if (!ws || !ws.hasFullscreen)
            return false;
        return ws.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1);
    }

    Connections {
        target: Hyprland.focusedWorkspace ?? null

        function onHasFullscreenChanged() {
            Hyprland.refreshToplevels();
        }
    }

    readonly property bool lockHeld: root.fullscreenOn
    readonly property bool blankHeld: root.fullscreenOn || root.mediaPlaying
    readonly property bool suspendHeld: root.fullscreenOn || root.mediaPlaying

    signal lockRequested()

    IdleMonitor {
        id: lockMonitor
        enabled: !root.lockHeld
        timeout: root.lockSecs
        respectInhibitors: true
        onIsIdleChanged: {
            if (!enabled || !isIdle)
                return;
            root.lockRequested();
        }
    }

    IdleMonitor {
        id: offMonitor
        enabled: !root.blankHeld
        timeout: root.offSecs
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) {
                if (enabled)
                    root.lightsOut();
            } else {
                // Always restore: a suppression flip must not leave the panel dim.
                root.lightsOn();
            }
        }
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: !root.suspendHeld
        timeout: root.suspendSecs
        respectInhibitors: true
        onIsIdleChanged: {
            if (!enabled || !isIdle)
                return;
            suspendProc.running = true;
        }
    }

    property int savedRaw: -1

    Process {
        id: levelProbe
        command: ["sh", "-c", "b=$(brightnessctl get) || exit 1; echo \"$b\""]
        stdout: StdioCollector {
            id: levelOut
            onStreamFinished: {
                const raw = parseInt(levelOut.text.trim(), 10);
                if (!isNaN(raw) && raw > 0) {
                    root.savedRaw = raw;
                    screenOff.running = true;
                }
            }
        }
    }

    Process {
        id: screenOff
        command: ["sh", "/home/pranav/.config/hypr/scripts/brightness.sh", "set", "1"]
    }

    Process {
        id: screenOn
    }

    function lightsOut() {
        if (root.savedRaw < 0)
            levelProbe.running = true;
        else
            screenOff.running = true;
    }

    function lightsOn() {
        if (root.savedRaw > 0) {
            screenOn.command = ["brightnessctl", "set", String(root.savedRaw)];
            screenOn.running = true;
            root.savedRaw = -1;
        }
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }
}
