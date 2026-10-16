// Horizontal value bar: rounded track + animated fill.
// Usage: StyledBar { value: 0.42 }

import QtQuick
import qs.modules

Item {
    id: root

    required property real value          // 0..1
    property color fillColor: Theme.colors.primary
    property color trackColor: Theme.colors.barTrack

    implicitWidth: Theme.sizes.barLength
    implicitHeight: Theme.sizes.barThickness

    Rectangle {                       // track
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {                       // fill
        height: parent.height
        width: Math.max(0, Math.min(1, root.value)) * parent.width
        radius: height / 2
        color: root.fillColor

        Behavior on width {
            animation: Theme.animation.value.createObject(this)
        }
    }
}