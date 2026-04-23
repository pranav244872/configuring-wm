// NavButton.qml — Circular navigation button
//
// Caelestia-style icon button:
//   - Circular with hover/press feedback
//   - Material Icons Round
//   - Subtle color transitions

import QtQuick

Rectangle {
    id: root

    required property var colors

    width: 36
    height: 36
    radius: width / 2

    // Subtle background on hover/press
    color: mouseArea.pressed ? colors.m3.surface_container_highest :
           mouseArea.containsMouse ? colors.m3.surface_container_high :
           "transparent"

    // Icon to display (Material Icons name)
    property string icon: "chevron_left"
    signal clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: colors.m3.on_surface_variant
        font.pixelSize: 20
        font.family: "Material Icons Round"
    }
}
