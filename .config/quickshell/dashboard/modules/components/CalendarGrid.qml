// CalendarGrid.qml — Month calendar with prev/next navigation
//
// 6x7 day grid with day headers, today highlighting.
// No event integration — just the visual calendar.

import QtQuick

Rectangle {
    id: root

    required property var colors
    color: "transparent"

    property date currentDate: new Date()
    property int currentYear: currentDate.getFullYear()
    property int currentMonth: currentDate.getMonth()

    readonly property real sideMargin: (width / 7 - 28) / 2

    function prevMonth() {
        const d = new Date(currentYear, currentMonth - 1, 1)
        currentYear = d.getFullYear()
        currentMonth = d.getMonth()
    }

    function nextMonth() {
        const d = new Date(currentYear, currentMonth + 1, 1)
        currentYear = d.getFullYear()
        currentMonth = d.getMonth()
    }

    function isToday(day) {
        const today = new Date()
        return day > 0 && currentYear === today.getFullYear() && currentMonth === today.getMonth() && day === today.getDate()
    }

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    readonly property int daysInMonth: new Date(root.currentYear, root.currentMonth + 1, 0).getDate()
    readonly property int firstDayOfWeek: {
        const dow = new Date(root.currentYear, root.currentMonth, 1).getDay()
        return dow === 0 ? 6 : dow - 1
    }

    // Header: month/year + navigation
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36

        Text {
            anchors.left: parent.left
            anchors.leftMargin: root.sideMargin
            anchors.verticalCenter: parent.verticalCenter
            text: root.monthNames[root.currentMonth] + " " + root.currentYear
            color: root.colors.m3.on_surface
            font.pixelSize: 16
            font.family: "Inter"
            font.weight: Font.Medium
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.sideMargin
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    color: root.colors.m3.on_surface_variant
                    font.pixelSize: 20
                    font.family: "Material Icons Round"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevMonth()
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "chevron_right"
                    color: root.colors.m3.on_surface_variant
                    font.pixelSize: 20
                    font.family: "Material Icons Round"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }
    }

    // Day headers
    Row {
        id: dayHeaderRow
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        height: 24
        spacing: 0

        Repeater {
            model: root.dayNames.length
            Text {
                width: dayHeaderRow.width / root.dayNames.length
                text: root.dayNames[index]
                color: root.colors.m3.on_surface_variant
                font.pixelSize: 11
                font.family: "Inter"
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Calendar grid
    Grid {
        id: calendarGrid
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 32
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: 42
            Item {
                id: dayCell
                width: calendarGrid.width / 7
                height: 32

                property int dayNum: {
                    const d = index - root.firstDayOfWeek + 1
                    return (d >= 1 && d <= root.daysInMonth) ? d : 0
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: root.isToday(dayCell.dayNum) ? root.colors.m3.primary : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.dayNum > 0 ? dayCell.dayNum : ""
                        color: {
                            if (dayCell.dayNum === 0) return "transparent"
                            if (root.isToday(dayCell.dayNum)) return root.colors.m3.on_primary
                            return root.colors.m3.on_surface
                        }
                        font.pixelSize: 12
                        font.family: "Inter"
                        font.weight: root.isToday(dayCell.dayNum) ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
