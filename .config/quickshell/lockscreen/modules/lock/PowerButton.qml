// PowerButton.qml — Single power action button
//
// Circular button with icon and tooltip on hover.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../qs/services"

Item {
    id: root

    required property string icon
    required property string label
    required property color buttonColor

    implicitWidth: 40
    implicitHeight: 40

    // Hover area
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }

    signal clicked()

    // Button background
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: mouseArea.containsMouse ? root.buttonColor : "transparent"
        opacity: mouseArea.containsMouse ? 0.15 : 1

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    // Icon
    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: "Material Icons Round"
        font.pointSize: 18
        color: root.buttonColor
    }

    // Tooltip
    Text {
        anchors {
            top: parent.bottom
            topMargin: 6
            horizontalCenter: parent.horizontalCenter
        }

        text: root.label
        color: Colors.m3.on_surface
        font.family: "Inter"
        font.pointSize: 10
        opacity: mouseArea.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
}
