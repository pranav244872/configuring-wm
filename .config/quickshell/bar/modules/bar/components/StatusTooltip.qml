// StatusTooltip.qml — Hover tooltip panel for status bar icons
//
// A full-surface PanelWindow (like TrayMenu) that positions a tooltip
// just below the hovered icon. Three modes:
//   wifi  → SSID + signal strength (read-only)
//   bt    → connected device name (read-only)
//   power → 3 power-profile selector buttons (interactive)
//
// No top-corner rounding (flush against the bar).
// Bottom-left + bottom-right rounded at 14px.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io

PanelWindow {
    id: root

    required property var colors
    property var parentScreen: null
    screen: parentScreen

    // Data fed from StatusBar
    property string networkSsid: ""
    property string networkSignal: ""
    property bool   wifiConnected: false
    property string powerProfile: "balanced"

    signal profileSelected(string profile)
    signal ppdRefreshNeeded()

    // Internal
    property int  mode: -1    // 0=wifi, 1=bt, 2=power
    property real targetCenterX: 0
    property bool isOpen: false

    // Keep visible during hide animation
    visible: isOpen || tooltipBox.opacity > 0

    color: "transparent"
    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: (isOpen && mode === 2)
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-status-tooltip"

    anchors { top: true; left: true; right: true; bottom: true }

    // Only accept input on the tooltip box; transparent elsewhere
    mask: Region { item: isOpen ? tooltipBox : null }

    // Dismiss on click outside
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        acceptedButtons: Qt.AllButtons
        onClicked: root.close()
        // Allow the tooltip box to handle its own clicks
        enabled: isOpen
    }

    // ── Tooltip box ──────────────────────────────────────────────────────────
    Rectangle {
        id: tooltipBox

        // Center under the icon, clamped to screen bounds
        x: Math.max(4,
            Math.min(root.width - width - 4,
                root.targetCenterX - width / 2))
        y: 40   // just below the 40px bar

        // Animate slide-down from bar
        readonly property real showY: 40
        readonly property real hideY: 28

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
        }

        transform: Translate {
            y: root.isOpen ? 0 : -12
            Behavior on y {
                NumberAnimation { duration: 220; easing.type: Easing.OutQuart }
            }
        }

        opacity: root.isOpen ? 1 : 0

        width: tooltipContent.implicitWidth + 24
        height: tooltipContent.implicitHeight + 16

        color: root.colors.m3.surface_container_high
        radius: 14

        // Square top-left and top-right (flush to bar)
        Rectangle {
            width: parent.width
            height: parent.radius
            color: parent.color
            anchors.top: parent.top
        }

        // Shadow
        layer.enabled: true

        // ── Content ──────────────────────────────────────────────────────────
        Item {
            id: tooltipContent
            anchors.centerIn: parent
            implicitWidth: modeLoader.implicitWidth
            implicitHeight: modeLoader.implicitHeight

            Loader {
                id: modeLoader
                sourceComponent: {
                    if (root.mode === 0) return wifiComp
                    if (root.mode === 1) return btComp
                    if (root.mode === 2) return powerComp
                    return null
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: {
                if (!containsMouse) root.hideIfNotHovered()
            }
        }
    }

    // ── WiFi info ────────────────────────────────────────────────────────────
    Component {
        id: wifiComp
        Column {
            spacing: 4
            width: 180

            Text {
                text: root.wifiConnected ? root.networkSsid : "Not connected"
                color: root.colors.m3.on_surface
                font.family: "Inter"
                font.weight: Font.SemiBold
                font.pixelSize: 13
            }
            Text {
                visible: root.networkSignal !== ""
                text: "Signal: " + root.networkSignal
                color: root.colors.m3.on_surface_variant
                font.family: "Inter"
                font.pixelSize: 11
            }
        }
    }

    // ── Bluetooth info ────────────────────────────────────────────────────────
    Component {
        id: btComp
        Column {
            spacing: 4
            width: 180

            Text {
                text: {
                    try {
                        const connected = Bluetooth.devices.values.filter(d => d.connected)
                        if (connected.length === 0) return "No devices connected"
                        return connected.map(d => d.name || d.address).join(", ")
                    } catch (e) { return "Bluetooth unavailable" }
                }
                color: root.colors.m3.on_surface
                font.family: "Inter"
                font.weight: Font.SemiBold
                font.pixelSize: 13
                wrapMode: Text.Wrap
                width: 180
            }

            Text {
                text: {
                    try {
                        const all = Bluetooth.devices.values
                        return all.length + " device" + (all.length !== 1 ? "s" : "") + " known"
                    } catch (e) { return "" }
                }
                color: root.colors.m3.on_surface_variant
                font.family: "Inter"
                font.pixelSize: 11
            }
        }
    }

    // ── Power profile picker ──────────────────────────────────────────────────
    Component {
        id: powerComp
        Column {
            spacing: 6
            width: 200

            Text {
                text: "Power Profile"
                color: root.colors.m3.on_surface_variant
                font.family: "Inter"
                font.weight: Font.Medium
                font.pixelSize: 11
                bottomPadding: 2
            }

            Repeater {
                model: [
                    { id: "power-saver",  label: "Power Saver",  icon: "battery_saver", color: "tertiary" },
                    { id: "balanced",     label: "Balanced",      icon: "balance",       color: "secondary" },
                    { id: "performance",  label: "Performance",   icon: "bolt",          color: "error" },
                ]

                delegate: Rectangle {
                    width: 200
                    height: 36
                    radius: 10
                    color: {
                        if (root.powerProfile === modelData.id) {
                            if (modelData.color === "tertiary")  return root.colors.m3.tertiary_container
                            if (modelData.color === "error")     return root.colors.m3.error_container
                            return root.colors.m3.secondary_container
                        }
                        return pfMa.containsMouse ? root.colors.m3.surface_variant : "transparent"
                    }

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: modelData.icon
                            font.family: "Material Icons Round"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                if (root.powerProfile === modelData.id) {
                                    if (modelData.color === "tertiary")  return root.colors.m3.on_tertiary_container
                                    if (modelData.color === "error")     return root.colors.m3.on_error_container
                                    return root.colors.m3.on_secondary_container
                                }
                                return root.colors.m3.on_surface_variant
                            }
                        }

                        Text {
                            text: modelData.label
                            font.family: "Inter"
                            font.weight: root.powerProfile === modelData.id ? Font.Bold : Font.Normal
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                if (root.powerProfile === modelData.id) {
                                    if (modelData.color === "tertiary")  return root.colors.m3.on_tertiary_container
                                    if (modelData.color === "error")     return root.colors.m3.on_error_container
                                    return root.colors.m3.on_secondary_container
                                }
                                return root.colors.m3.on_surface
                            }
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        // Active check mark
                        Text {
                            text: "check"
                            font.family: "Material Icons Round"
                            font.pixelSize: 14
                            color: {
                                if (modelData.color === "tertiary")  return root.colors.m3.on_tertiary_container
                                if (modelData.color === "error")     return root.colors.m3.on_error_container
                                return root.colors.m3.on_secondary_container
                            }
                            visible: root.powerProfile === modelData.id
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: pfMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const profile = modelData.id
                            Quickshell.execDetached(["powerprofilesctl", "set", profile])
                            root.powerProfile = profile
                            root.profileSelected(profile)
                            Qt.callLater(() => root.ppdRefreshNeeded())
                        }
                    }
                }
            }
        }
    }

    // ── API ──────────────────────────────────────────────────────────────────
    function showWifi(globalPos) {
        mode = 0
        targetCenterX = globalPos.x
        isOpen = true
    }

    function showBluetooth(globalPos) {
        mode = 1
        targetCenterX = globalPos.x
        isOpen = true
    }

    function showPower(globalPos) {
        mode = 2
        targetCenterX = globalPos.x
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    // Called by HoverHandler.onHoveredChanged when the icon loses hover;
    // we only actually close if the tooltip box itself isn't hovered.
    function hideIfNotHovered() {
        // Small delay to allow mouse to move into the tooltip box without flicker
        hideDelayTimer.restart()
    }

    Timer {
        id: hideDelayTimer
        interval: 120
        onTriggered: {
            // If the tooltip box contains the mouse, don't close
            root.isOpen = false
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.mode === 2
        Keys.onEscapePressed: root.close()
    }
}
