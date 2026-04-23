pragma ComponentBehavior: Bound

// StatusBar.qml — Right-side status cluster for the top bar
//
// Layout: [SystemTray] [wifi ─ bt ─ power] [battery]
//
// The [wifi ─ bt ─ power] pill is one clickable unit → opens the side panel.
// Each icon inside it also has a hover tooltip that slides down from the bar:
//   wifi  → SSID + signal info
//   bt    → connected device name
//   power → 3 power-profile buttons (interactive)
// Battery is display-only (no hover).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import "../../../../qs/services"

Item {
    id: root

    required property var colors

    // Expose for tooltip window to read
    property string networkIcon: "signal_wifi_off"
    property string networkSsid: "Disconnected"
    property string networkSignal: ""
    property bool   wifiConnected: false

    property string powerProfile: "balanced"     // power-saver | balanced | performance
    property int  sinkVolume: 0
    property bool sinkMuted: false
    property int  sourceVolume: 0
    property bool sourceMuted: false

    implicitHeight: 36
    implicitWidth: contentRow.implicitWidth

    // ── Network polling (nmcli) ──────────────────────────────────────────────
    Process {
        id: nmcliWifi
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "dev", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                for (const line of lines) {
                    const parts = line.split(":")
                    if (parts[0] === "yes") {
                        const sig = parseInt(parts[1]) || 0
                        root.networkSsid   = parts[2] || "Unknown"
                        root.networkSignal = sig + "%"
                        root.wifiConnected = true
                        if (sig >= 80)      root.networkIcon = "network_wifi"
                        else if (sig >= 60) root.networkIcon = "network_wifi_3_bar"
                        else if (sig >= 40) root.networkIcon = "network_wifi_2_bar"
                        else if (sig >= 20) root.networkIcon = "network_wifi_1_bar"
                        else                root.networkIcon = "signal_wifi_0_bar"
                        netTimer.restart()
                        return
                    }
                }
                nmcliEth.running = true
            }
        }
        onExited: (code) => { if (code !== 0) netTimer.restart() }
    }

    Process {
        id: nmcliEth
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,NAME", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let found = false
                for (const line of lines) {
                    const p = line.split(":")
                    if (p[2] === "connected" && (p[1] === "ethernet" || p[1] === "802-3-ethernet")) {
                        root.networkIcon   = "cable"
                        root.networkSsid   = p[3] || "Ethernet"
                        root.networkSignal = "Wired"
                        root.wifiConnected = true
                        found = true
                        break
                    }
                }
                if (!found) {
                    root.networkIcon   = "signal_wifi_off"
                    root.networkSsid   = "Disconnected"
                    root.networkSignal = ""
                    root.wifiConnected = false
                }
                netTimer.restart()
            }
        }
    }

    Timer { id: netTimer; interval: 5000; repeat: false; onTriggered: nmcliWifi.running = true }

    // ── Power profile polling ────────────────────────────────────────────────
    Process {
        id: ppdGet
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.powerProfile = text.trim()
                ppdTimer.restart()
            }
        }
    }

    Timer { id: ppdTimer; interval: 10000; repeat: false; onTriggered: ppdGet.running = true }

    // ── Volume polling ───────────────────────────────────────────────────────
    Process {
        id: volSinkProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s+([\d.]+)/)
                root.sinkVolume = m ? Math.round(parseFloat(m[1]) * 100) : 0
                root.sinkMuted  = text.includes("[MUTED]")
                if (root.sinkVolume > 100) root.sinkVolume = 100 // clamp
                volSourceProc.running = true
            }
        }
    }
    Process {
        id: volSourceProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s+([\d.]+)/)
                root.sourceVolume = m ? Math.round(parseFloat(m[1]) * 100) : 0
                root.sourceMuted  = text.includes("[MUTED]")
                if (root.sourceVolume > 100) root.sourceVolume = 100 // clamp
                volTimer.restart()
            }
        }
    }
    Timer { id: volTimer; interval: 2000; repeat: false; onTriggered: volSinkProc.running = true }

    // ── Layout ───────────────────────────────────────────────────────────────
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 10

        // ── Status cluster pill ─────────────────────────────────────────────
        Rectangle {
            id: clusterPill
            height: 28
            width: clusterRow.implicitWidth + 20
            radius: 14
            color: clusterMa.containsMouse
                ? root.colors.m3.surface_container_high
                : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: clusterRow
                    anchors.centerIn: parent
                    spacing: 12

                    // Volume
                    Row {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: {
                                if (root.sinkMuted) return "volume_off"
                                if (root.sinkVolume > 50) return "volume_up"
                                if (root.sinkVolume > 0) return "volume_down"
                                return "volume_mute"
                            }
                            color: root.sinkMuted ? root.colors.m3.outline : root.colors.m3.secondary
                            font.pixelSize: 16
                            font.family: "Material Icons Round"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.sinkVolume + "%"
                            color: root.colors.m3.on_surface_variant
                            font.pixelSize: 12
                            font.family: "Inter"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.sinkMuted
                        }
                    }

                    // Mic
                    Row {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: root.sourceMuted ? "mic_off" : "mic"
                            color: root.sourceMuted ? root.colors.m3.outline : root.colors.m3.secondary
                            font.pixelSize: 16
                            font.family: "Material Icons Round"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.sourceVolume + "%"
                            color: root.colors.m3.on_surface_variant
                            font.pixelSize: 12
                            font.family: "Inter"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.sourceMuted
                        }
                    }

                    // Brightness
                    Row {
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        property real br: Brightness.getActiveMonitor() ? Brightness.getActiveMonitor().brightness : 0.5
                        Text {
                            text: {
                                if (parent.br > 0.6) return "brightness_high"
                                if (parent.br > 0.3) return "brightness_medium"
                                return "brightness_low"
                            }
                            color: root.colors.m3.secondary
                            font.pixelSize: 16
                            font.family: "Material Icons Round"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: Math.round(parent.br * 100) + "%"
                            color: root.colors.m3.on_surface_variant
                            font.pixelSize: 12
                            font.family: "Inter"
                            font.weight: Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Divider
                    Rectangle {
                        width: 1
                        height: 16
                        color: root.colors.m3.outline_variant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // WiFi icon
                Text {
                    id: wifiIcon
                    text: root.networkIcon
                    color: root.wifiConnected ? root.colors.m3.secondary : root.colors.m3.outline
                    font.pixelSize: 18
                    font.family: "Material Icons Round"
                    anchors.verticalCenter: parent.verticalCenter

                    // Show wifi hover tooltip
                    HoverHandler {
                        id: wifiHover
                        onHoveredChanged: {
                            if (hovered) {
                                statusTooltip.showWifi(wifiIcon.mapToGlobal(wifiIcon.width / 2, 40))
                            } else {
                                statusTooltip.hideIfNotHovered()
                            }
                        }
                    }
                }

                // Bluetooth icon
                Text {
                    id: btIcon
                    text: {
                        try {
                            if (!Bluetooth.defaultAdapter?.enabled) return "bluetooth_disabled"
                            if (Bluetooth.devices.values.some(d => d.connected)) return "bluetooth_connected"
                            return "bluetooth"
                        } catch (e) { return "bluetooth_disabled" }
                    }
                    color: {
                        try {
                            if (!Bluetooth.defaultAdapter?.enabled) return root.colors.m3.outline
                            if (Bluetooth.devices.values.some(d => d.connected)) return root.colors.m3.primary
                            return root.colors.m3.secondary
                        } catch (e) { return root.colors.m3.outline }
                    }
                    font.pixelSize: 18
                    font.family: "Material Icons Round"
                    anchors.verticalCenter: parent.verticalCenter

                    HoverHandler {
                        id: btHover
                        onHoveredChanged: {
                            if (hovered) {
                                statusTooltip.showBluetooth(btIcon.mapToGlobal(btIcon.width / 2, 40))
                            } else {
                                statusTooltip.hideIfNotHovered()
                            }
                        }
                    }
                }

                // Power-profile icon
                Text {
                    id: powerIcon
                    text: {
                        if (root.powerProfile === "power-saver") return "battery_saver"
                        if (root.powerProfile === "performance") return "bolt"
                        return "balance"
                    }
                    color: {
                        if (root.powerProfile === "power-saver") return root.colors.m3.tertiary
                        if (root.powerProfile === "performance") return root.colors.m3.error
                        return root.colors.m3.secondary
                    }
                    font.pixelSize: 18
                    font.family: "Material Icons Round"
                    anchors.verticalCenter: parent.verticalCenter

                    HoverHandler {
                        id: powerHover
                        onHoveredChanged: {
                            if (hovered) {
                                statusTooltip.showPower(powerIcon.mapToGlobal(powerIcon.width / 2, 40))
                            } else {
                                statusTooltip.hideIfNotHovered()
                            }
                        }
                    }
                }
            }

            // Whole-cluster click → open side panel
            MouseArea {
                id: clusterMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "sidepanel", "toggle"])
            }
        }

        // ── Battery ─────────────────────────────────────────────────────────
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: {
                    const p = UPower.displayDevice.percentage
                    const s = UPower.displayDevice.state
                    const charging = s === UPowerDeviceState.Charging
                        || s === UPowerDeviceState.FullyCharged
                        || s === UPowerDeviceState.PendingCharge
                    if (charging) return "\uf0e7"   // nf-fa-bolt (charging)
                    if (p >= 0.90) return "\uf240"
                    if (p >= 0.80) return "\uf241"  // These are standard Nerd Font battery glyphs
                    if (p >= 0.70) return "\uf242"
                    if (p >= 0.60) return "\uf243"
                    if (p >= 0.50) return "\uf244"
                    if (p >= 0.40) return "\uf245"
                    if (p >= 0.30) return "\uf246"
                    if (p >= 0.20) return "\uf247"
                    if (p >= 0.10) return "\uf248"
                    return "\uf249"
                }
                color: {
                    if (!UPower.onBattery || UPower.displayDevice.percentage > 0.2)
                        return root.colors.m3.secondary
                    return root.colors.m3.error
                }
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font Mono"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                color: {
                    if (!UPower.onBattery || UPower.displayDevice.percentage > 0.2)
                        return root.colors.m3.secondary
                    return root.colors.m3.error
                }
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Hover tooltip (shared PanelWindow) ───────────────────────────────────
    StatusTooltip {
        id: statusTooltip
        colors: root.colors
        parentScreen: Quickshell.screens[0]
        networkSsid: root.networkSsid
        networkSignal: root.networkSignal
        wifiConnected: root.wifiConnected
        powerProfile: root.powerProfile
        onPowerProfileChanged: (profile) => {
            root.powerProfile = profile
        }
        onPpdRefreshNeeded: ppdGet.running = true
    }
}
