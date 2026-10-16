// Clock: compact 24-hour time (HH:mm) updated on the minute.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.widgets

Item {
    id: root

    implicitWidth: timeText.implicitWidth
    implicitHeight: timeText.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    StyledText {
        id: timeText
        anchors.centerIn: parent

        text: Qt.formatDateTime(clock.date, "ddd, MMM d · HH:mm").toUpperCase()
        color: Theme.colors.fgLayer1
        font.family: Theme.font.main
        font.pixelSize: Theme.bar.clockSize
        font.weight: Theme.bar.clockWeight
        font.letterSpacing: Theme.frame.tracking
    }
}
