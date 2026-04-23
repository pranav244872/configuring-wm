// SliderControl.qml — Labelled slider for volume, mic, brightness
//
// Emits changed(value) on drag; parent handles the actual system command.
// value: 0.0 – 1.0

import QtQuick
import QtQuick.Controls as QC
import "../../../qs/services"

Item {
    id: root

    property var colors: Colors

    property string icon: "volume_up"
    property string label: ""
    property real value: 0.5       // 0.0 – 1.0
    property string valueLabel: Math.round(value * 100) + "%"

    signal changed(real newValue)

    implicitHeight: 60
    implicitWidth: 200

    Column {
        anchors.fill: parent
        spacing: 8

        // ── Label row ──────────────────────────────────────────────────────
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: root.icon
                font.family: "Material Icons Round"
                font.pixelSize: 18
                color: root.colors.m3.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.label
                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: root.colors.m3.on_surface
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 1; height: 1 }

            Text {
                text: root.valueLabel
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: root.colors.m3.on_surface_variant
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Track ──────────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 24

            // Track background
            Rectangle {
                id: trackBg
                width: parent.width
                height: 6
                radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: root.colors.m3.surface_container_highest
            }

            // Filled portion
            Rectangle {
                id: trackFill
                height: 6
                radius: 3
                anchors.left: trackBg.left
                anchors.right: handle.left
                anchors.verticalCenter: parent.verticalCenter
                color: root.colors.m3.primary
            }

            // Handle
            Rectangle {
                id: handle
                width: 20
                height: 20
                radius: 10
                color: root.colors.m3.primary
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0,
                    Math.min(trackBg.width - width,
                        trackBg.width * root.value - width / 2))

                Behavior on x {
                    enabled: !sliderMa.pressed
                    NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                }

                scale: sliderMa.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            // Drag surface
            MouseArea {
                id: sliderMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function valueAt(mx) {
                    return Math.max(0.0, Math.min(1.0, mx / trackBg.width))
                }

                onPressed: mouse => {
                    const v = valueAt(mouse.x)
                    root.value = v
                    root.changed(v)
                }
                onPositionChanged: mouse => {
                    if (pressed) {
                        const v = valueAt(mouse.x)
                        root.value = v
                        root.changed(v)
                    }
                }
            }
        }
    }
}
