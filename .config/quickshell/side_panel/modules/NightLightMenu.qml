import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../qs/services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "qs-nightlight-menu"
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    color: shouldShow ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
    Behavior on color { ColorAnimation { duration: 200 } }

    property bool shouldShow: NightLightService.showMenu
    visible: shouldShow || menuContainer.opacity > 0

    onShouldShowChanged: {
        // NightLightMenu has no InputFields, so no manual focus clearing is needed
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("[NightLightMenu] Outside area clicked. Closing.")
            NightLightService.closeMenu()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (shouldShow) NightLightService.closeMenu()
        }
    }

    // ── Bottom sheet ────────────────────────────────────────────────────────
    Rectangle {
        id: menuContainer
        width: 400
        height: 280
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.shouldShow ? 0 : -height - 20
        opacity: root.shouldShow ? 1 : 0
        color: Colors.m3.surface_container
        radius: 24

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Square off the bottom corners
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 24
            color: parent.color
        }

        // Block clicks from propagating
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            anchors.bottomMargin: 16
            spacing: 20

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰖔"
                    font.family: "Material Design Icons"
                    font.pixelSize: 24
                    color: NightLightService.enabled ? Colors.m3.primary : Colors.m3.on_surface_variant
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Night Light"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: Colors.m3.on_surface
                    }
                    Text {
                        text: NightLightService.enabled
                              ? NightLightService.temperature + "K · Active"
                              : "Reduces blue light"
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: Colors.m3.on_surface_variant
                    }
                }

                // Toggle
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 26
                    radius: 13
                    color: NightLightService.enabled ? Colors.m3.primary : Colors.m3.surface_container_highest
                    border.color: NightLightService.enabled ? "transparent" : Colors.m3.outline
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: NightLightService.enabled ? parent.width - width - 4 : 4
                        color: NightLightService.enabled ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NightLightService.toggle()
                    }
                }
            }

            // ── Temperature labels ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Warmer"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Colors.m3.on_surface_variant
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: NightLightService.temperature + "K"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: NightLightService.enabled ? Colors.m3.primary : Colors.m3.on_surface_variant
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Cooler"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: Colors.m3.on_surface_variant
                }
            }

            // ── Temperature slider ──────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                // Track background (gradient warm→cool)
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FF6B35" }   // Warm (1000K)
                        GradientStop { position: 0.3; color: "#FFB347" }   // Warm-mid
                        GradientStop { position: 0.6; color: "#FFE4B5" }   // Mid
                        GradientStop { position: 1.0; color: "#E8F4FD" }   // Cool (6500K)
                    }
                    opacity: NightLightService.enabled ? 0.4 : 0.15
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Active fill
                Rectangle {
                    height: parent.height
                    width: tempThumb.x + tempThumb.width
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#FF6B35" }
                        GradientStop { position: 1.0; color: "#FFB347" }
                    }
                    opacity: NightLightService.enabled ? 0.6 : 0.2
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Thumb
                Rectangle {
                    id: tempThumb
                    height: parent.height
                    width: 56
                    radius: height / 2
                    color: NightLightService.enabled ? Colors.m3.primary : Colors.m3.outline
                    Behavior on color { ColorAnimation { duration: 200 } }

                    // Map temperature (1000-6500) to position (inverted: left=warm=low temp)
                    x: {
                        const normalized = (NightLightService.temperature - 1000) / (6500 - 1000)
                        return normalized * (parent.width - width)
                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: tempSliderMa.pressed ? 0 : 150
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: NightLightService.enabled ? "󰖔" : "󰖕"
                        font.family: "Material Design Icons"
                        font.pixelSize: 18
                        color: NightLightService.enabled ? Colors.m3.on_primary : Colors.m3.on_surface
                    }
                }

                MouseArea {
                    id: tempSliderMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: NightLightService.enabled

                    function updateTemp(mouseX) {
                        if (width <= 0) return
                        let minX = tempThumb.width / 2
                        let maxX = width - (tempThumb.width / 2)
                        let clampedX = Math.max(minX, Math.min(maxX, mouseX))
                        let normalized = (clampedX - minX) / (maxX - minX)
                        // Map 0-1 to 1000-6500K
                        let temp = Math.round(1000 + normalized * 5500)
                        // Snap to nearest 100
                        temp = Math.round(temp / 100) * 100
                        NightLightService.setTemp(temp)
                    }

                    onPressed: mouse => updateTemp(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed) updateTemp(mouse.x)
                    }
                }
            }

            // ── Preset buttons ──────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { label: "Cozy", temp: 2500, icon: "🕯️" },
                        { label: "Warm", temp: 3500, icon: "🌅" },
                        { label: "Default", temp: 4500, icon: "🌙" },
                        { label: "Light", temp: 5500, icon: "☁️" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 18
                        color: NightLightService.temperature === modelData.temp && NightLightService.enabled
                               ? Colors.m3.primary_container
                               : (presetMa.containsMouse ? Colors.m3.surface_container_highest : Colors.m3.surface_container_high)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: modelData.icon
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.label
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: NightLightService.temperature === modelData.temp && NightLightService.enabled
                                       ? Colors.m3.on_primary_container
                                       : Colors.m3.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }
                        MouseArea {
                            id: presetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!NightLightService.enabled) NightLightService.enable()
                                NightLightService.setTemp(modelData.temp)
                            }
                        }
                    }
                }
            }
        }
    }
}
