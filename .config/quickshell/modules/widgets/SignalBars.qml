// Four-bar signal meter. Rectangles instead of a wifi glyph: crisp at 16-20px
// and it matches the square Chaldea frame language.
import QtQuick
import qs.modules

Item {
    id: root

    property real level: 0 // 0.0 - 1.0
    readonly property int activeCount: Math.max(1, Math.ceil(level * 4))

    property color color: Theme.colors.fgLayer0
    property color offColor: ColorUtils.transparentize(Theme.colors.fgLayer1, 0.72)

    property int barWidth: 3
    property int gap: 2
    property int maxHeight: 14

    implicitWidth: 4 * barWidth + 3 * gap
    implicitHeight: maxHeight

    Repeater {
        model: 4

        delegate: Rectangle {
            required property int index

            readonly property real h: Math.round(root.maxHeight * (0.3 + 0.7 * index / 3))

            x: index * (root.barWidth + root.gap)
            y: root.maxHeight - h
            width: root.barWidth
            height: h
            radius: 0
            color: index < root.activeCount ? root.color : root.offColor

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animation.valueDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveOut
                }
            }
        }
    }
}
