pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool showMenu: false
    property int temperature: 4500
    property bool userOverride: false
    property bool isNightPhase: false

    // Auto-enable after 7 PM loop
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const hour = new Date().getHours()
            const shouldAutoEnable = (hour >= 19 || hour < 6)

            // Reset user override strictly when the time phase flips between day/night
            if (shouldAutoEnable !== root.isNightPhase) {
                root.isNightPhase = shouldAutoEnable
                root.userOverride = false
                console.log("[NightLight] Phase flipped. Resetting user override.")
            }

            // Do not aggressively auto-toggle if user explicitly made a choice
            if (root.userOverride) return

            if (shouldAutoEnable && !root.enabled) {
                console.log("[NightLight] Auto-enabling (hour:", hour + ")")
                root.enable()
            } else if (!shouldAutoEnable && root.enabled) {
                console.log("[NightLight] Auto-disabling (hour:", hour + ")")
                root.disable()
            }
        }
    }

    function enable() {
        if (!enabled) {
            enabled = true
            // Start the daemon if not running, then set temperature via IPC
            Quickshell.execDetached(["bash", "-c",
                "pgrep -x hyprsunset >/dev/null || nohup hyprsunset >/dev/null 2>&1 & sleep 0.3; hyprctl hyprsunset temperature " + temperature.toString()])
        }
    }

    function disable() {
        if (enabled) {
            enabled = false
            // Reset to identity (no color change) via IPC — keeps daemon alive
            Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
        }
    }

    function toggle() {
        userOverride = true
        if (enabled) disable()
        else enable()
    }

    function setTemp(temp) {
        temperature = Math.round(temp)
        if (enabled) {
            // Live IPC update — instant, no restart needed
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", temperature.toString()])
        }
    }

    function openMenu() {
        showMenu = true
    }

    function closeMenu() {
        showMenu = false
    }
}
