import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "components/network"
import "../../qs/services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "qs-network-menu"
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    anchors { top: true; bottom: true; left: true; right: true }
    color: shouldShow ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
    Behavior on color { ColorAnimation { duration: 200 } }

    property bool shouldShow: NetworkMenuService.showMenu
    visible: shouldShow || menuContainer.opacity > 0

    onShouldShowChanged: {
        // No InputFields in NetworkMenu that need manual focus clearing
        // (PanelWindow does not expose forceActiveFocus)
    }

    MouseArea { 
        anchors.fill: parent
        onClicked: {
            console.log("[NetworkMenu] Outside area clicked. Closing menu.")
            NetworkMenuService.close()
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            console.log("[NetworkMenu] Escape shortcut activated. Closing menu.")
            if (shouldShow) NetworkMenuService.close()
        }
    }

    // ── Sliding bottom sheet ────────────────────────────────────────────────
    Rectangle {
        id: menuContainer
        width: 440
        height: 560
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.shouldShow ? 0 : -height - 20
        opacity: root.shouldShow ? 1 : 0
        color: Colors.m3.surface_container
        radius: 24

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        // Square off the bottom corners (flush with screen edge)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 24
            color: parent.color
        }

        // Block clicks from propagating through
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            anchors.bottomMargin: 8
            spacing: 0

            // ── Tab bar ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 24
                color: Colors.m3.surface_container_high

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    // Wi-Fi tab button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 20
                        color: NetworkMenuService.activeTab === "wifi" ? Colors.m3.primary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰤨"
                                font.family: "Material Design Icons"
                                font.pixelSize: 18
                                color: NetworkMenuService.activeTab === "wifi" ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Wi-Fi"
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: NetworkMenuService.activeTab === "wifi" ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkMenuService.activeTab = "wifi"
                        }
                    }

                    // Bluetooth tab button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 20
                        color: NetworkMenuService.activeTab === "bluetooth" ? Colors.m3.primary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "󰂯"
                                font.family: "Material Design Icons"
                                font.pixelSize: 18
                                color: NetworkMenuService.activeTab === "bluetooth" ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Bluetooth"
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: NetworkMenuService.activeTab === "bluetooth" ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkMenuService.activeTab = "bluetooth"
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 16 }

            // ── Tab content ─────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Wi-Fi Tab — instant crossfade, no sliding
                WifiTab {
                    id: wifiTab
                    isActiveTab: NetworkMenuService.activeTab === "wifi"
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: NetworkMenuService.activeTab === "wifi" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                }

                // Bluetooth Tab — instant crossfade, no sliding
                BluetoothTab {
                    id: btTab
                    isActiveTab: NetworkMenuService.activeTab === "bluetooth"
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: NetworkMenuService.activeTab === "bluetooth" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                }
            }
        }
    }
}
