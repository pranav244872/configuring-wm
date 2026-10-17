// Compact square toggle (Chaldea frame language): hairline track, square knob
// that slides on the short curve. Shared by the dashboard sections.
import QtQuick
import qs.modules

Item {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 34
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: root.checked ? Theme.colors.primary : "transparent"
        border.width: Theme.frame.line
        border.color: root.checked ? Theme.colors.primary : Theme.colors.outline

        Rectangle {
            width: 12
            height: 12
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.colors.fgPrimary : Theme.colors.subtext

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animation.moveDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveMove
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveOut
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
