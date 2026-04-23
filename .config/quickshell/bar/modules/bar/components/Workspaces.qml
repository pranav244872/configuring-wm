// Workspaces.qml — Workspace indicator pills
//
// Caelestia-inspired pill container with expanding workspace indicators.
// Active workspace: Wide pill, m3onPrimary text, m3primary background.
// Inactive workspace: Circular pill, m3onSurfaceVariant text, m3surfaceVariant background.
// Click to switch workspace.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root

    required property var colors

    color: colors.m3.surface_container_high
    radius: height / 2

    implicitHeight: 32
    
    // Automatically calculates width based on the sum of all expanded/collapsed children
    implicitWidth: workspacesRow.implicitWidth + 8

    Behavior on implicitWidth {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }

    Row {
        id: workspacesRow
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                id: wsDelegate
                
                // Uniform size for all workspaces to prevent formatting breakage
                width: 24
                height: 24
                radius: height / 2

                // Active: primary fill. Inactive hover: outline_variant. Inactive: surface_variant
                color: modelData.active ? colors.m3.primary : (ma.containsMouse ? colors.m3.outline_variant : colors.m3.surface_variant)
                
                Behavior on color {
                    ColorAnimation { duration: 100; easing.type: Easing.OutQuad }
                }

                Text {
                    text: modelData.id
                    anchors.centerIn: parent
                    color: modelData.active ? colors.m3.on_primary : colors.m3.on_surface_variant
                    font.pixelSize: 11
                    font.family: "Inter"
                    font.weight: modelData.active ? Font.Bold : Font.Medium

                    Behavior on color {
                        ColorAnimation { duration: 100; easing.type: Easing.OutQuad }
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}
