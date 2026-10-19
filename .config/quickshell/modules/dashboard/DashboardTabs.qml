// Dashboard tab row: numbered equal-width slots with a solid accent block
// behind the active one, sliding on the move curve. Deliberately the same
// treatment as the bar's workspace indicator (solid block, dark text, tracked
// mono), so the sheet speaks the bar's language instead of material pills.
//
// Stacking note: the row-wide catcher is declared FIRST and the per-cell hit
// areas after it. Later siblings take input first, which is what keeps a cell
// clickable on top of the catcher (the same rule the notification card's ✕
// needed, see notes/quickshell.md).
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    // Tab labels, in order; the index in this array is the tab index.
    property var labels: []
    property int currentIndex: 0

    signal selected(int index)

    readonly property int count: root.labels.length
    readonly property real cellWidth: root.count > 0 ? root.width / root.count : root.width
    readonly property int inset: Theme.sizes.dashboardTabInset

    implicitHeight: Theme.sizes.dashboardTabHeight

    function step(delta) {
        root.selected(Math.max(0, Math.min(root.count - 1, root.currentIndex + delta)));
    }

    // The sliding block, under everything.
    Rectangle {
        id: block

        x: root.currentIndex * root.cellWidth + root.inset
        y: root.inset
        width: Math.max(0, root.cellWidth - 2 * root.inset)
        height: root.height - 2 * root.inset
        color: Theme.colors.primary

        Behavior on x {
            NumberAnimation {
                duration: Theme.animation.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveMove
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveMove
            }
        }
    }

    // Row-wide catcher: a wheel over the row moves between tabs, and a click
    // that lands between the cells is swallowed here instead of reaching the
    // sheet's click-away. The cells handle their own clicks on top of this.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
        }
        onWheel: (event) => root.step(event.angleDelta.y < 0 ? 1 : -1)
    }

    Repeater {
        model: root.labels

        delegate: Item {
            id: cell

            required property int index
            required property string modelData

            x: index * root.cellWidth
            width: root.cellWidth
            height: root.height

            readonly property bool active: index === root.currentIndex

            Rectangle {
                anchors.fill: parent
                visible: cellArea.containsMouse && !cell.active
                color: Theme.colors.stateHover
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                StyledText {
                    text: String(cell.index + 1).padStart(2, "0")
                    color: cell.active ? Theme.colors.fgPrimary : Theme.colors.primary
                    opacity: cell.active ? 0.8 : 1
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.tracking

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animation.valueDuration
                        }
                    }
                }

                StyledText {
                    text: cell.modelData
                    color: cell.active ? Theme.colors.fgPrimary : Theme.colors.subtext
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.tracking

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animation.valueDuration
                        }
                    }
                }
            }

            MouseArea {
                id: cellArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(cell.index)
            }
        }
    }

    // Hairline the tabs sit on; each tab's own controls row follows below.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.frame.line
        color: Theme.colors.outline
    }
}
