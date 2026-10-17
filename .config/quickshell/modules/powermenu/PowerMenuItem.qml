// Session entry row. Chaldea outlined-button behaviour: square, uppercase
// tracked label, and an accent fill that slides in from the left on hover.
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    required property string glyph
    required property string label
    signal activated()

    // Live hover comes from the MouseArea; `forceActive` lets previews pin the
    // state without faking mouse events.
    property bool forceActive: false
    readonly property bool active: forceActive || mouseArea.containsMouse

    implicitWidth: parent?.width ?? 264
    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        clip: true // the fill waits just off the left edge
        color: "transparent"

        Rectangle {
            width: parent.width
            height: parent.height
            x: root.active ? 0 : -width - 1
            color: Theme.colors.primary

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animation.enterDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveOut
                }
            }
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            font.family: Theme.font.icon
            font.pixelSize: 20
            color: root.active ? Theme.colors.fgPrimary : Theme.colors.subtext

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animation.valueDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveOut
                }
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pixelSize: Theme.font.size.md
            font.letterSpacing: Theme.frame.tracking
            color: root.active ? Theme.colors.fgPrimary : Theme.colors.fgLayer0

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animation.valueDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveOut
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
