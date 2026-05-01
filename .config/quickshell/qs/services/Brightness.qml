pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Brightness.qml — Event-driven backlight service
//
// Watches /sys/class/backlight via FileView (inotify) for instant updates
// when brightness changes from ANY source (keybinds, other apps, etc.).

Singleton {
    id: root

    readonly property list<Monitor> monitors: variants.instances

    function getActiveMonitor(): var {
        return monitors[0]
    }

    // Default to 1 to avoid division by zero, updated asynchronously
    property int maxBrightness: 1
    property int currentRawBrightness: 0

    Process {
        command: ["cat", "/sys/class/backlight/intel_backlight/max_brightness"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim())
                if (val > 0) {
                    root.maxBrightness = val
                    root.updateMonitors()
                }
            }
        }
    }

    // Watch the sysfs brightness file for instant updates
    FileView {
        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const val = parseInt(text())
            if (!isNaN(val)) {
                root.currentRawBrightness = val
                root.updateMonitors()
            }
        }
    }

    function updateMonitors() {
        if (root.maxBrightness > 0 && root.monitors.length > 0) {
            const pct = root.currentRawBrightness / root.maxBrightness
            for (let i = 0; i < root.monitors.length; i++) {
                root.monitors[i].brightness = pct
            }
        }
    }

    Variants {
        id: variants
        model: Quickshell.screens
        Monitor {}
    }

    component Monitor: QtObject {
        id: monitor
        required property ShellScreen modelData
        property real brightness: 0.5

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value))
            brightness = value
            const rounded = Math.round(value * 100)
            Quickshell.execDetached(["brightnessctl", "s", rounded + "%"])
            // brightnessctl updates sysfs → FileView detects → brightness updates
        }
    }
}
