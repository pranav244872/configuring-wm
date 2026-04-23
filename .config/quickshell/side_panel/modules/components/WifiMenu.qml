// WifiMenu.qml — WiFi network browser (slides up from bottom)
//
// Full-width panel anchored to bottom of screen.
// Top-left + top-right rounded; no bottom rounding (flush to screen edge).
//
// Features:
//   - Lists available networks (nmcli dev wifi list)
//   - Connected network highlighted at top
//   - Click unsaved / new network → item expands inline with password field
//   - Click already-saved network → reconnects immediately
//   - Scan button refreshes the list
//   - Toggle (enable/disable wifi adapter)

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../../../qs/services"

PanelWindow {
    id: root

    property var colors: Colors
    property var parentScreen: null
    screen: parentScreen

    property bool isOpen: false

    function open() {
        isOpen = true
        refreshNetworks()
    }

    function close() {
        isOpen = false
        expandedSsid = ""
        passwordText = ""
    }

    visible: isOpen || container.opacity > 0

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-wifi-menu"

    anchors { left: true; right: true; bottom: true; top: true }

    mask: Region { item: isOpen ? container : null }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        onClicked: root.close()
    }

    // ── State ────────────────────────────────────────────────────────────────
    property var networks: []        // [{ssid, signal, security, connected, saved}]
    property string expandedSsid: "" // which network shows the password field
    property string passwordText: ""
    property bool scanning: false
        property string connectingTo: ""
    property string statusMsg: ""

    // ── Network scanning ─────────────────────────────────────────────────────
    Process {
        id: wifiListProc
        // Fields: IN-USE,BSSID,SSID,MODE,CHAN,RATE,SIGNAL,BARS,SECURITY
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const seen = new Set()
                const result = []
                for (const line of lines) {
                    if (!line.trim()) continue
                    // Fields separated by ':'  but SSIDs can contain ':'  → split max 4
                    const parts = line.split(":")
                    if (parts.length < 3) continue
                    const inUse    = parts[0] === "*"
                    const ssid     = parts[1]
                    if (!ssid || ssid === "--") continue
                    if (seen.has(ssid)) continue
                    seen.add(ssid)
                    const signal   = parseInt(parts[2]) || 0
                    const security = parts.slice(3).join(":").trim()
                    const secured  = security.length > 0 && security !== "--"
                    result.push({ ssid, signal, security: secured ? security : "", connected: inUse, saved: inUse })
                }
                // Sort: connected first, then by signal
                result.sort((a, b) => {
                    if (a.connected !== b.connected) return a.connected ? -1 : 1
                    return b.signal - a.signal
                })
                root.networks = result
                root.scanning = false
            }
        }
        onExited: { root.scanning = false }
    }

    
    Process {
        id: connectProc
        property string targetSsid: ""
        property string targetPassword: ""
        command: {
            if (targetPassword.length > 0) {
                return ["nmcli", "dev", "wifi", "connect", targetSsid, "password", targetPassword]
            }
            return ["nmcli", "dev", "wifi", "connect", targetSsid]
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root.connectingTo = ""
                if (text.includes("successfully") || text.includes("activated")) {
                    root.statusMsg = "Connected to " + connectProc.targetSsid
                    root.expandedSsid = ""
                    root.passwordText = ""
                    Qt.callLater(root.refreshNetworks)
                } else {
                    root.statusMsg = "Failed. Check password."
                }
                statusClearTimer.restart()
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                root.connectingTo = ""
                root.statusMsg = "Connection failed."
                statusClearTimer.restart()
            }
        }
    }

    Timer { id: statusClearTimer; interval: 3000; onTriggered: root.statusMsg = "" }

    function refreshNetworks() {
        root.scanning = true
        wifiListProc.running = true
    }

    function connectTo(ssid, password) {
        connectProc.targetSsid = ssid
        connectProc.targetPassword = password || ""
        root.connectingTo = ssid
        connectProc.running = true
    }

    function disconnectCurrent() {
        Quickshell.execDetached(["nmcli", "dev", "disconnect", "wifi"])
        Qt.callLater(() => {
            Qt.callLater(root.refreshNetworks)
        })
    }

    function toggleWifi() {
        const cmd = Network.wifiEnabled ? "off" : "on"
        Quickshell.execDetached(["nmcli", "radio", "wifi", cmd])
        Network.wifiEnabled = !Network.wifiEnabled
        if (Network.wifiEnabled) {
            Qt.callLater(root.refreshNetworks)
        }
    }

    // ── Container (slides up from bottom) ────────────────────────────────────
    Rectangle {
        id: container

        // Position: bottom-right, same width as side panel
        anchors.right: parent.right
        // Slide from bottom edge
        y: root.isOpen
            ? (root.height - height)
            : root.height

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
        }

        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }

        width: 400
        height: Math.min(root.height * 0.7, contentCol.implicitHeight + 24)

        color: root.colors ? root.colors.m3.surface : "#0f1417"
        radius: 20

        // Square bottom corners (flush to screen edge)
        Rectangle {
            width: parent.width
            height: parent.radius
            color: parent.color
            anchors.bottom: parent.bottom
        }

        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Column {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
                topMargin: 20
            }
            spacing: 0

            // ── Header ────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 44

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    spacing: 10

Item {
            width: parent.width
            height: 48
            visible: root.networks.length === 0 && !root.scanning
            Text {
                anchors.centerIn: parent
                text: "No networks found"
                font.family: "Inter"
                font.pixelSize: 13
                color: root.colors ? root.colors.m3.outline : "#888"
            }
        }

        Item {
            width: parent.width
            height: 48
            visible: root.scanning
            Text {
                anchors.centerIn: parent
                text: "Scanning…"
                font.family: "Inter"
                font.pixelSize: 13
                color: root.colors ? root.colors.m3.on_surface_variant : "#aaa"
            }
        }

                    Text {
                        text: "Wi-Fi"
                        font.family: "Inter"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: root.colors ? root.colors.m3.on_surface : "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Status message
                    Text {
                        text: root.statusMsg
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: root.statusMsg.startsWith("Failed") || root.statusMsg.startsWith("Connection")
                            ? (root.colors ? root.colors.m3.error : "red")
                            : (root.colors ? root.colors.m3.primary : "green")
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.statusMsg.length > 0
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: 8

                    // Scan button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: scanMa.containsMouse
                            ? (root.colors ? root.colors.m3.surface_variant : "#444")
                            : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "refresh"
                            font.family: "Material Icons Round"
                            font.pixelSize: 18
                            color: root.colors ? root.colors.m3.on_surface_variant : "white"
                            opacity: root.scanning ? 0.4 : 1
                        }
                        MouseArea {
                            id: scanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.scanning
                            onClicked: root.refreshNetworks()
                        }
                    }

                    // Enable/disable toggle
                    Rectangle {
                        width: 52; height: 28; radius: 14
                        color: Network.wifiEnabled
                            ? (root.colors ? root.colors.m3.primary : "#4da6d4")
                            : (root.colors ? root.colors.m3.surface_container_highest : "#333")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: Network.wifiEnabled ? parent.width - width - 4 : 4
color: Network.wifiEnabled
                                ? (root.colors ? root.colors.m3.on_primary : "white")
                                : (root.colors ? root.colors.m3.outline : "#888")
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleWifi()
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: root.colors ? root.colors.m3.outline_variant : "#333"
                opacity: 0.4
            }

            Item { width: 1; height: 9 }

            // ── Network list ─────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 48
                visible: !Network.wifiEnabled
                Text {
                    anchors.centerIn: parent
                    text: "Wi-Fi is disabled"
                    font.family: "Inter"
                    font.pixelSize: 14
                    color: root.colors ? root.colors.m3.outline : "#888"
                }
            }

            Column {
                visible: Network.wifiEnabled
                width: parent.width
                spacing: 4

                Repeater {
                    model: Network.wifiEnabled ? root.networks : []

                    delegate: Column {
                        width: parent.width
                        spacing: 0

                        readonly property bool expanded: root.expandedSsid === modelData.ssid
                        readonly property bool isConnecting: root.connectingTo === modelData.ssid

                        // ── Network row ─────────────────────────────────────
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 12
                            color: {
                                if (modelData.connected)   return root.colors ? root.colors.m3.secondary_container : "#264"
                                if (netMa.containsMouse)   return root.colors ? root.colors.m3.surface_container_highest : "#333"
                                return "transparent"
                            }
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // WiFi signal icon
                                Text {
                                    text: {
                                        const s = modelData.signal
                                        if (s >= 75) return "network_wifi"
                                        if (s >= 50) return "network_wifi_3_bar"
                                        if (s >= 25) return "network_wifi_2_bar"
                                        return "network_wifi_1_bar"
                                    }
                                    font.family: "Material Icons Round"
                                    font.pixelSize: 20
                                    color: modelData.connected
                                        ? (root.colors ? root.colors.m3.primary : "cyan")
                                        : (root.colors ? root.colors.m3.on_surface_variant : "#aaa")
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 50 - (modelData.security ? 24 : 0) - 24 - 24

                                    Text {
                                        text: modelData.ssid
                                        font.family: "Inter"
                                        font.weight: modelData.connected ? Font.SemiBold : Font.Normal
                                        font.pixelSize: 13
                                        color: root.colors ? root.colors.m3.on_surface : "white"
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        visible: modelData.connected || parent.parent.parent.isConnecting
                                        text: parent.parent.parent.isConnecting ? "Connecting…" : "Connected"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: root.colors ? root.colors.m3.primary : "cyan"
                                    }
                                }

                                Item { Layout.fillWidth: true; width: 1; height: 1 }

                                // Lock icon for secured networks
                                Text {
                                    visible: modelData.security.length > 0
                                    text: "lock"
                                    font.family: "Material Icons Round"
                                    font.pixelSize: 14
                                    color: root.colors ? root.colors.m3.outline : "#888"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Disconnect button for connected network
                                Text {
                                    visible: modelData.connected
                                    text: "close"
                                    font.family: "Material Icons Round"
                                    font.pixelSize: 16
                                    color: root.colors ? root.colors.m3.error : "red"
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.disconnectCurrent()
                                    }
                                }

                                // Expand/collapse chevron
                                Text {
                                    visible: !modelData.connected
                                    text: parent.parent.parent.expanded ? "expand_less" : "chevron_right"
                                    font.family: "Material Icons Round"
                                    font.pixelSize: 16
                                    color: root.colors ? root.colors.m3.on_surface_variant : "#aaa"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: netMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.connected) return
                                    if (root.expandedSsid === modelData.ssid) {
                                        root.expandedSsid = ""
                                    } else {
                                        root.expandedSsid = modelData.ssid
                                        root.passwordText = ""
                                    }
                                }
                            }
                        }

                        // ── Password field (expands inline) ─────────────────
                        Rectangle {
                            visible: parent.expanded && !modelData.connected
                            width: parent.width
                            height: visible ? 64 : 0
                            color: "transparent"

                            Behavior on height {
                                NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
                            }

                            Row {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 12
                                    topMargin: 6
                                    bottomMargin: 6
                                }
                                spacing: 8

                                // Password input pill
                                Rectangle {
                                    width: parent.width - connectBtn.width - cancelBtn.width - 24
                                    height: 44
                                    radius: 22
                                    color: root.colors ? root.colors.m3.surface_container_high : "#1e1e2e"
                                    border.color: pwInput.activeFocus
                                        ? (root.colors ? root.colors.m3.primary : "cyan")
                                        : (root.colors ? root.colors.m3.outline_variant : "#444")
                                    border.width: 1

                                    Row {
                                        anchors {
                                            fill: parent
                                            leftMargin: 14
                                            rightMargin: 8
                                        }
                                        spacing: 6

                                        TextInput {
                                            id: pwInput
                                            width: parent.width - eyeBtn.width - 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: root.colors ? root.colors.m3.on_surface : "white"
                                            font.family: "Inter"
                                            font.pixelSize: 13
                                            echoMode: showPw ? TextInput.Normal : TextInput.Password
                                            text: root.passwordText
                                            onTextChanged: root.passwordText = text
                                            Keys.onReturnPressed: {
                                                root.connectTo(root.expandedSsid, root.passwordText)
                                            }
                                            Keys.onEscapePressed: {
                                                root.expandedSsid = ""
                                            }
                                            focus: parent.parent.parent.visible

                                            property bool showPw: false

                                            // Placeholder
                                            Text {
                                                anchors.fill: parent
                                                anchors.verticalCenter: parent.verticalCenter
                                                verticalAlignment: Text.AlignVCenter
                                                text: "Password"
                                                color: root.colors ? root.colors.m3.outline : "#888"
                                                font.family: "Inter"
                                                font.pixelSize: 13
                                                visible: pwInput.text.length === 0
                                            }
                                        }

                                        // Show/hide password eye
                                        Rectangle {
                                            id: eyeBtn
                                            width: 28; height: 28; radius: 14
                                            color: eyeMa.containsMouse
                                                ? (root.colors ? root.colors.m3.surface_variant : "#333")
                                                : "transparent"
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: pwInput.showPw ? "visibility_off" : "visibility"
                                                font.family: "Material Icons Round"
                                                font.pixelSize: 16
                                                color: root.colors ? root.colors.m3.on_surface_variant : "#aaa"
                                            }

                                            MouseArea {
                                                id: eyeMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: pwInput.showPw = !pwInput.showPw
                                            }
                                        }
                                    }
                                }

                                // Connect button
                                Rectangle {
                                    id: connectBtn
                                    width: 80; height: 44; radius: 22
                                    color: connMa.containsMouse
                                        ? (root.colors ? root.colors.m3.primary : "#4da6d4")
                                        : (root.colors ? root.colors.m3.primary_container : "#1e4d66")

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.family: "Inter"
                                        font.weight: Font.SemiBold
                                        font.pixelSize: 12
                                        color: connMa.containsMouse
                                            ? (root.colors ? root.colors.m3.on_primary : "white")
                                            : (root.colors ? root.colors.m3.on_primary_container : "#8dcff1")
                                    }

                                    MouseArea {
                                        id: connMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.connectTo(root.expandedSsid, root.passwordText)
                                    }
                                }

                                // Cancel button
                                Rectangle {
                                    id: cancelBtn
                                    width: 44; height: 44; radius: 22
                                    color: cancelMa.containsMouse
                                        ? (root.colors ? root.colors.m3.surface_variant : "#333")
                                        : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "close"
                                        font.family: "Material Icons Round"
                                        font.pixelSize: 18
                                        color: root.colors ? root.colors.m3.on_surface_variant : "#aaa"
                                    }

                                    MouseArea {
                                        id: cancelMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.expandedSsid = ""
                                            root.passwordText = ""
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    width: parent.width
                    height: 48
                    visible: root.networks.length === 0 && !root.scanning
                    Text {
                        anchors.centerIn: parent
                        text: "No networks found"
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: root.colors ? root.colors.m3.outline : "#888"
                    }
                }

                Item {
                    width: parent.width
                    height: 48
                    visible: root.scanning
                    Text {
                        anchors.centerIn: parent
                        text: "Scanning…"
                        font.family: "Inter"
                        font.pixelSize: 13
                        color: root.colors ? root.colors.m3.on_surface_variant : "#aaa"
                    }
                }
            }

            Item { width: 1; height: 8 }
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.isOpen
        Keys.onEscapePressed: root.close()
    }
}
