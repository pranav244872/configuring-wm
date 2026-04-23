pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiEnabled: false
    property string activeSsid: "Disconnected"
    property int activeSignal: 0

    function toggleWifi(): void {
        const cmd = wifiEnabled ? "off" : "on"
        enableWifiProc.command = ["nmcli", "radio", "wifi", cmd]
        enableWifiProc.running = true
    }

    // Serialized refresh: check wifi status first, then active network
    function refresh(): void {
        if (!wifiStatusProc.running) {
            wifiStatusProc.running = true
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled"
                if (!root.wifiEnabled) {
                    root.activeSsid = "Disconnected"
                    root.activeSignal = 0
                } else {
                    activeNetProc.running = true
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[Network] wifiStatusProc exited with code:", exitCode)
            }
        }
    }

    Process {
        id: activeNetProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.wifiEnabled) return;

                const lines = text.trim().split("\n")
                let foundActive = false

                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue;

                    const parts = lines[i].split(":")
                    if (parts.length >= 3 && parts[0] === "yes") {
                        root.activeSsid = parts[1] || "Hidden Network"
                        root.activeSignal = parseInt(parts[2], 10) || 0
                        foundActive = true
                        break
                    }
                }

                if (!foundActive) {
                    root.activeSsid = "Disconnected"
                    root.activeSignal = 0
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[Network] activeNetProc exited with code:", exitCode)
            }
        }
    }

    Process {
        id: enableWifiProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        onExited: (exitCode, exitStatus) => {
            root.refresh()
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
