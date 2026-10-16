// Month calendar card: end-4 grid math, our chrome. Window wrapper lives in
// CalendarWidget.qml; benches render this directly.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import "calendar_layout.js" as Cal

Item {
    id: root

    property int monthShift: 0
    // todayTick refreshes both every minute: the pill moves at midnight, and
    // the viewed month rolls over on month boundaries
    property var viewing: (root.todayTick, Cal.shiftedDate(monthShift))
    // todayTick re-fires the layout every minute for midnight rollover
    property var grid: (root.todayTick, Cal.layout(viewing, monthShift === 0))
    property int todayTick: 0

    // Screen bounds for the drag clamp, set by whoever positions this card
    property real boundW: 1920
    property real boundH: 1080

    signal dragFinished()
    readonly property bool dragging: dragArea.drag.active

    // Grid math is exact (7x36 + 6x6 + 32 padding); height follows content
    implicitWidth: 320
    implicitHeight: col.implicitHeight + 32

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.todayTick++
    }

    function title() {
        return (root.monthShift !== 0 ? "• " : "") + Qt.formatDateTime(root.viewing, "MMMM yyyy").toUpperCase();
    }

    Rectangle {
        id: widget
        anchors.fill: parent
        radius: 0
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline

        CornerTicks {
            anchors.fill: parent
        }

        // One drag surface for the whole card (built-in C++ drag: smooth,
        // thresholded, clamped). filterChildren lets it override for drags
        // while descendants keep their clicks; wheel shifts months.
        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.threshold: 6
            drag.smoothed: true
            drag.filterChildren: true
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: root.boundW - root.width
            drag.maximumY: root.boundH - root.height
            onReleased: root.dragFinished()
            onWheel: (event) => {
                if (event.angleDelta.y > 0)
                    root.monthShift--;
                else if (event.angleDelta.y < 0)
                    root.monthShift++;
            }
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 16
            spacing: 6

            // Header: month title (click = back to today) + chevrons
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Item {
                    Layout.preferredWidth: titleLabel.implicitWidth
                    Layout.preferredHeight: 32

                        StyledText {
                            id: titleLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.title()
                            font.pixelSize: Theme.font.size.md
                            font.weight: Font.DemiBold
                            font.letterSpacing: Theme.frame.titleTrack
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthShift = 0
                        }
                    }

                Item {
                    Layout.fillWidth: true
                }

                Repeater {
                    model: [
                        { glyph: "chevron_left", dir: -1 },
                        { glyph: "chevron_right", dir: 1 }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 0
                        color: navMa.containsMouse ? Theme.colors.stateHover : "transparent"

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.glyph
                            font.family: Theme.font.icon
                            font.pixelSize: 20
                            color: Theme.colors.fgLayer0
                        }

                        MouseArea {
                            id: navMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthShift += parent.modelData.dir
                        }
                    }
                }
            }

            // Weekday header
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: Cal.weekDays

                    delegate: StyledText {
                        required property string modelData

                        Layout.preferredWidth: 36
                        text: modelData.toUpperCase()
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.font.size.xs
                        font.weight: Font.DemiBold
                        font.letterSpacing: Theme.frame.tracking
                        color: Theme.colors.subtext
                    }
                }
            }

            // Day grid
            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 7
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: root.grid

                    delegate: Rectangle {
                        required property var modelData

                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 0
                        color: modelData.today === 1 ? Theme.colors.primary
                            : (dayMa.containsMouse ? Theme.colors.stateHover : "transparent")

                        StyledText {
                            anchors.centerIn: parent
                            text: parent.modelData.day
                            font.pixelSize: Theme.font.size.sm
                            font.weight: parent.modelData.today === 1 ? Font.Black : Font.Medium
                            color: parent.modelData.today === 1 ? Theme.colors.fgPrimary
                                : (parent.modelData.today === 0 ? Theme.colors.fgLayer0
                                                                 : ColorUtils.transparentize(Theme.colors.fgLayer1, 0.60))
                        }

                        MouseArea {
                            id: dayMa
                            anchors.fill: parent
                            hoverEnabled: true
                            // Hover only: presses fall through to the card drag area
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }
    }
}
