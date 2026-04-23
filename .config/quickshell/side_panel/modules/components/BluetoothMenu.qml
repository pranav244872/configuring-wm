// BluetoothMenu.qml — Bluetooth device browser (slides up from bottom)
//
// Same slide-up pattern as WifiMenu.
// Uses Quickshell.Bluetooth for device state (no separate bluetoothctl process
// needed for basic connect/disconnect — Quickshell 0.2+ handles it natively).
// Falls back to bluetoothctl process calls for pairing/scanning.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
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
        startScan()
    }

    function close() {
        isOpen = false
        stopScan()
    }

    visible: isOpen || container.opacity > 0

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-bt-menu"

    anchors { left: true; right: true; bottom: true; top: true }

    mask: Region { item: isOpen ? container : null }

    MouseArea {
        anchors.fill: parent
        enabled: isOpen
        onClicked: root.close()
    }

    // ── State ────────────────────────────────────────────────────────────────
    readonly property bool scanning: Bluetooth.defaultAdapter?.discovering ?? false
    property string statusMsg: ""
    property string connectingTo: ""   // device address

    function startScan() {
        if (Bluetooth.defaultAdapter) {
    Bluetooth.defaultAdapter.discovering = true
}
scanStopTimer.restart()
    }

    function stopScan() {
        scanStopTimer.stop()
        scanStopTimer.stop()
if (Bluetooth.defaultAdapter) {
    Bluetooth.defaultAdapter.discovering = false
}
    }

    Timer {
        id: scanStopTimer
        interval: 10000
        onTriggered: {
scanStopTimer.stop()
if (Bluetooth.defaultAdapter) {
    Bluetooth.defaultAdapter.discovering = false
}
        }
    }

    
    Process {
        id: connectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "connect", targetAddress]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connectingTo = ""
                if (text.includes("successful") || text.includes("Connected")) {
                    root.statusMsg = "Connected"
                } else {
                    root.statusMsg = "Connection failed"
                }
                clearStatus.restart()
            }
        }
        onExited: (code) => {
            if (code !== 0) {
                root.connectingTo = ""
                root.statusMsg = "Failed to connect"
                clearStatus.restart()
            }
        }
    }

    Process {
        id: disconnectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "disconnect", targetAddress]
        stdout: StdioCollector {
            onStreamFinished: {
                root.statusMsg = "Disconnected"
                clearStatus.restart()
            }
        }
    }

    Timer { id: clearStatus; interval: 3000; onTriggered: root.statusMsg = "" }

    // ── Sorted device list ───────────────────────────────────────────────────
    readonly property var sortedDevices: {
        try {
            const devs = Bluetooth.devices.values.slice()
            devs.sort((a, b) => {
                if (a.connected !== b.connected) return a.connected ? -1 : 1
                if (a.paired !== b.paired) return a.paired ? -1 : 1
                return (a.name || "").localeCompare(b.name || "")
            })
            return devs
        } catch (e) { return [] }
    }

    // ── Container ────────────────────────────────────────────────────────────
    Rectangle {
        id: container

        anchors.right: parent.right
        y: root.isOpen ? (root.height - height) : root.height

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuart }
        }

        opacity: root.isOpen ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }

        width: 400
        height: Math.min(root.height * 0.65, contentCol.implicitHeight + 24)

        color: root.colors ? root.colors.m3.surface : "#0f1417"
        radius: 20

        // Square bottom corners
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

                    Text {
                        text: "bluetooth"
                        font.family: "Material Icons Round"
                        font.pixelSize: 20
                        color: root.colors ? root.colors.m3.primary : "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Bluetooth"
                        font.family: "Inter"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: root.colors ? root.colors.m3.on_surface : "white"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.statusMsg
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: root.statusMsg.startsWith("F") || root.statusMsg.startsWith("f")
                            ? (root.colors ? root.colors.m3.error : "red")
                            : (root.colors ? root.colors.m3.primary : "cyan")
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.statusMsg.length > 0
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: 8

                    // Scan indicator / button
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: root.scanning
                            ? (root.colors ? root.colors.m3.primary_container : "#1e4d66")
                            : (scanBtnMa.containsMouse
                                ? (root.colors ? root.colors.m3.surface_variant : "#333")
                                : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: root.scanning ? "radar" : "search"
                            font.family: "Material Icons Round"
                            font.pixelSize: 18
                            color: root.scanning
                                ? (root.colors ? root.colors.m3.on_primary_container : "white")
                                : (root.colors ? root.colors.m3.on_surface_variant : "#aaa")
                        }

                        MouseArea {
                            id: scanBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.scanning ? root.stopScan() : root.startScan()
                        }
                    }

                    // Enable/disable toggle
                    Rectangle {
                        width: 52; height: 28; radius: 14
                        property bool btEnabled: {
                            try { return Bluetooth.defaultAdapter?.enabled ?? false } catch (e) { return false }
                        }
                        color: btEnabled
                            ? (root.colors ? root.colors.m3.primary : "#4da6d4")
                            : (root.colors ? root.colors.m3.surface_container_highest : "#333")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.btEnabled ? parent.width - width - 4 : 4
                            color: parent.btEnabled
                                ? (root.colors ? root.colors.m3.on_primary : "white")
                                : (root.colors ? root.colors.m3.outline : "#888")
                            Behavior on x { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                try {
                                    if (Bluetooth.defaultAdapter) {
                                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                    }
                                } catch (e) {}
                            }
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width; height: 1
                color: root.colors ? root.colors.m3.outline_variant : "#333"
                opacity: 0.4
            }

            Item { width: 1; height: 12 }

            // ── Device list ───────────────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.sortedDevices

                    delegate: Rectangle {
                        width: parent.width
                        height: 56
                        radius: 12

                        readonly property bool isConnecting: root.connectingTo === modelData.address

                        color: {
                            if (modelData.connected) return root.colors ? root.colors.m3.secondary_container : "#264"
                            if (devMa.containsMouse) return root.colors ? root.colors.m3.surface_container_highest : "#333"
                            return root.colors ? root.colors.m3.surface_container : "#1e1e2e"
                        }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            // Device type icon
                            Text {
                                text: {
                                    const t = (modelData.type || "").toLowerCase()
                                    if (t.includes("audio") || t.includes("headset") || t.includes("headphone"))
                                        return "headphones"
                                    if (t.includes("keyboard")) return "keyboard"
                                    if (t.includes("mouse"))    return "mouse"
                                    if (t.includes("phone"))    return "smartphone"
                                    if (t.includes("speaker"))  return "speaker"
                                    if (t.includes("watch"))    return "watch"
                                    return "bluetooth"
                                }
                                font.family: "Material Icons Round"
                                font.pixelSize: 22
                                color: modelData.connected
                                    ? (root.colors ? root.colors.m3.primary : "cyan")
                                    : (root.colors ? root.colors.m3.on_surface_variant : "#aaa")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                width: parent.width - 50 - 70
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.name || modelData.address || "Unknown Device"
                                    font.family: "Inter"
                                    font.weight: modelData.connected ? Font.SemiBold : Font.Normal
                                    font.pixelSize: 13
                                    color: root.colors ? root.colors.m3.on_surface : "white"
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: {
                                        if (isConnecting) return "Connecting…"
                                        if (modelData.connected) return "Connected"
                                        if (modelData.paired) return "Paired"
                                        return modelData.address || ""
                                    }
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    color: modelData.connected
                                        ? (root.colors ? root.colors.m3.primary : "cyan")
                                        : (root.colors ? root.colors.m3.outline : "#888")
                                }
                            }

                            Item { Layout.fillWidth: true; width: 1; height: 1 }

                            // Connect / Disconnect button
                            Rectangle {
                                width: 68; height: 30; radius: 15
                                anchors.verticalCenter: parent.verticalCenter
                                color: modelData.connected
                                    ? (actionMa.containsMouse
                                        ? (root.colors ? root.colors.m3.error_container : "#400")
                                        : (root.colors ? root.colors.m3.surface_container_highest : "#333"))
                                    : (actionMa.containsMouse
                                        ? (root.colors ? root.colors.m3.primary : "#4da6d4")
                                        : (root.colors ? root.colors.m3.primary_container : "#1e4d66"))

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Disconnect" : (isConnecting ? "…" : "Connect")
                                    font.family: "Inter"
                                    font.weight: Font.Medium
                                    font.pixelSize: 10
                                    color: modelData.connected
                                        ? (actionMa.containsMouse
                                            ? (root.colors ? root.colors.m3.on_error_container : "red")
                                            : (root.colors ? root.colors.m3.on_surface_variant : "#aaa"))
                                        : (actionMa.containsMouse
                                            ? (root.colors ? root.colors.m3.on_primary : "white")
                                            : (root.colors ? root.colors.m3.on_primary_container : "#8dcff1"))
                                }

                                MouseArea {
                                    id: actionMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !isConnecting
                                    onClicked: {
                                        const addr = modelData.address
                                        if (modelData.connected) {
                                            disconnectProc.targetAddress = addr
                                            disconnectProc.running = true
                                        } else {
                                            root.connectingTo = addr
                                            connectProc.targetAddress = addr
                                            connectProc.running = true
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: devMa
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onClicked: mouse => mouse.accepted = false
                        }
                    }
                }

                // Empty state
                Text {
                    visible: root.sortedDevices.length === 0
                    text: root.scanning ? "Scanning for devices…" : "No paired devices found"
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: root.colors ? root.colors.m3.outline : "#888"
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 16
                    bottomPadding: 16
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
