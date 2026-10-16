// Idle service: staged inactivity timers with inhibitor support. FINAL
// timings active (lock 3m, screen off 5m); suspend stays OFF until the lock
// round-trip is proven live (never suspend the machine from a test run).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    readonly property int lockAfter: 180
    readonly property int offAfter: 300
    readonly property int suspendAfter: 600

    // Set to false so it doesn't lock every 30s while you work
    readonly property bool testing: false
    readonly property int lockSecs: root.testing ? 30 : root.lockAfter
    readonly property int offSecs: root.testing ? 45 : root.offAfter
    readonly property bool suspendOn: false

    signal lockRequested()

    IdleMonitor {
        id: lockMonitor
        enabled: true
        timeout: root.lockSecs
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lockRequested();
        }
    }

    IdleMonitor {
        id: offMonitor
        enabled: true
        timeout: root.offSecs
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lightsOut();
            else
                root.lightsOn();
        }
    }

    IdleMonitor {
        id: suspendMonitor
        enabled: root.suspendOn
        timeout: root.suspendAfter
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
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
