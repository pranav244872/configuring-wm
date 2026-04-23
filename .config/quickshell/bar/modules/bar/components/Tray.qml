// Tray.qml — System tray icons
//
// Displays system tray items (network manager, bluetooth manager, etc.)
// Left-click to activate, right-click for secondary action.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property var colors

    implicitHeight: 36
    implicitWidth: SystemTray.items.values.length > 0 ? iconsRow.implicitWidth + 16 : 0
    visible: SystemTray.items.values.length > 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
    }

    Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items.values

            Rectangle {
                width: 20
                height: 20
                radius: width / 2
                color: "transparent"

                IconImage {
                    anchors.fill: parent
                    source: modelData.icon
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            modelData.activate()
                        } else {
                            if (modelData.menu) {
                                // Toggle logic to prevent double-opening crashes
                                if (trayMenu.isOpen && trayMenu.menuHandle === modelData.menu) {
                                    trayMenu.close()
                                } else {
                                    console.log("Opening tray menu for", modelData.id)
                                    trayMenu.menuHandle = modelData.menu
                                    var globalPos = iconsRow.mapToGlobal(parent.x + parent.width / 2, 0)
                                    trayMenu.targetX = globalPos.x
                                    trayMenu.targetY = 40 // Attach exactly to the bottom of the 40px top bar
                                    trayMenu.open()
                                }
                            } else {
                                console.log("No menu found for", modelData.id, "- using secondaryActivate()")
                                modelData.secondaryActivate()
                            }
                        }
                    }
                }
            }
        }
    }

    TrayMenu {
        id: trayMenu
        colors: root.colors
        parentScreen: Quickshell.screens[0]
    }
}
