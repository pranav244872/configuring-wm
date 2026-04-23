// TabBar.qml — Material 3 styled tab bar
//
// Three tabs: Overview, Media, Wallpapers
// Active tab has primary-colored pill indicator.

import QtQuick

Item {
    id: root

    required property var colors
    property int currentIndex: 0
    signal tabClicked(int index)

    implicitHeight: 36
    visible: true

    Row {
        anchors.fill: parent
        spacing: 4

        Repeater {
            id: tabRepeater
            model: [
                { icon: "dashboard", label: "Overview" },
                { icon: "music_note", label: "Media" },
                { icon: "wallpaper", label: "Wallpapers" }
            ]

            Item {
                width: (root.width - (tabRepeater.count - 1) * 4) / tabRepeater.count
                height: root.height

                property bool isActive: root.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    radius: 18
                    color: parent.isActive ? root.colors.m3.secondary_container : "transparent"
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: modelData.icon
                        color: parent.parent.isActive ? root.colors.m3.on_secondary_container : root.colors.m3.on_surface_variant
                        font.pixelSize: 18
                        font.family: "Material Icons Round"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: modelData.label
                        color: parent.parent.isActive ? root.colors.m3.on_secondary_container : root.colors.m3.on_surface_variant
                        font.pixelSize: 13
                        font.family: "Inter"
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabClicked(index)
                }
            }
        }
    }
}
