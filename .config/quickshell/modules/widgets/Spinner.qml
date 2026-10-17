// Loading spinner in the Chaldea square language: eight square dots in a ring
// whose brightness chases around.
//
// Deliberately rotation-free and glyph-free: StyledText renders with
// Text.NativeRendering, so rotating an icon glyph pixelates it. Axis-aligned
// squares snapped to whole pixels stay razor sharp at any size.
import QtQuick
import qs.modules

Item {
    id: root

    property int size: 18
    property color color: Theme.colors.primary
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    readonly property int dot: Math.max(3, Math.round(size / 6))
    readonly property real radius: size / 2 - dot / 2

    property real phase: 0

    NumberAnimation on phase {
        running: root.running
        from: 0
        to: 1
        duration: 900
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    Repeater {
        model: 8

        delegate: Rectangle {
            required property int index

            readonly property real angle: index * Math.PI / 4
            readonly property real strength: Math.pow(1 - ((root.phase + index / 8) % 1), 2)

            width: root.dot
            height: root.dot
            radius: 0
            color: root.color
            opacity: 0.12 + 0.88 * strength

            // Snap to whole pixels: fractional positions blur a 2px square.
            x: Math.round(root.width / 2 + Math.cos(angle) * root.radius - width / 2)
            y: Math.round(root.height / 2 + Math.sin(angle) * root.radius - height / 2)
        }
    }
}
