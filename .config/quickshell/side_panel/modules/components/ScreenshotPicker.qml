// ScreenshotPicker.qml — Small floating picker for screenshot modes
//
// Three options: Region, Fullscreen, Window
// Appears just below the screenshot toggle button.
// Calls hyprshot with the appropriate mode.

import QtQuick
import Quickshell
import "../../../qs/services"

Rectangle {
    id: root

    property var colors: Colors

    signal dismissed()

    width: 180
    height: optionsCol.implicitHeight + 16
    radius: 14
    color: root.colors.m3.surface_container_high

    // Square top corners (will be positioned touching the toggle button)
    Rectangle {
        width: parent.width
        height: parent.radius
        color: parent.color
        anchors.top: parent.top
    }

    Column {
        id: optionsCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 8
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 4

        Repeater {
            model: [
                { label: "Region",      icon: "crop",        mode: "region"     },
                { label: "Fullscreen",  icon: "fullscreen",  mode: "output"     },
                { label: "Window",      icon: "web_asset",   mode: "window"     },
            ]

            delegate: Rectangle {
                width: parent.width
                height: 40
                radius: 10
                color: optMa.containsMouse
                    ? root.colors.m3.secondary_container
                    : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Text {
                        text: modelData.icon
                        font.family: "Material Icons Round"
                        font.pixelSize: 18
                        color: optMa.containsMouse
                            ? root.colors.m3.on_secondary_container
                            : root.colors.m3.on_surface_variant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.label
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: optMa.containsMouse
                            ? root.colors.m3.on_secondary_container
                            : root.colors.m3.on_surface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: optMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const mode = modelData.mode
                        Quickshell.execDetached(["hyprshot", "-m", mode])
                        root.dismissed()
                    }
                }
            }
        }
    }
}
