// Clock.qml — Date and time display (side-by-side)
//
// Caelestia-inspired horizontal clock:
//   calendar_month icon + "Mon 5" + separator + "06:30 PM"
//
// Date: Inter, 13px, m3tertiary
// Time: JetBrains Mono Nerd Font Mono, 13px, m3tertiary

import QtQuick
import Quickshell

Item {
    id: root

    required property var colors

    implicitHeight: 32
    // Calculate width from content
    implicitWidth: clockRow.implicitWidth + 16

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 6

        // Calendar icon
        Text {
            text: "calendar_month"
            color: colors.m3.tertiary
            font.pixelSize: 16
            font.family: "Material Icons Round"
            anchors.verticalCenter: parent.verticalCenter
        }

        // Date text
        Text {
            id: dateText
            property string currentDate: ""
            text: currentDate
            color: colors.m3.tertiary
            font.pixelSize: 12
            font.family: "Inter"
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    dateText.currentDate = Qt.formatDate(now, "ddd d")
                }
            }

            Component.onCompleted: {
                var now = new Date()
                currentDate = Qt.formatDate(now, "ddd d")
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: 14
            color: colors.m3.tertiary
            opacity: 0.3
            anchors.verticalCenter: parent.verticalCenter
        }

        // Time text
        Text {
            id: timeText
            property string currentTime: ""
            text: currentTime
            color: colors.m3.tertiary
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font Mono"
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    timeText.currentTime = Qt.formatTime(now, "hh:mm A")
                }
            }

            Component.onCompleted: {
                var now = new Date()
                currentTime = Qt.formatTime(now, "hh:mm A")
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["qs", "ipc", "call", "dashboard", "toggle"])
        }
    }
}
