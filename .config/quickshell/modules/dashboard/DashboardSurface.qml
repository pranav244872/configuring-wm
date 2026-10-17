// Dashboard sheet body: square floating panel with the Chaldea hairline frame
// and accent corner ticks (mirrors PowerMenuSurface / CalendarCard).
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline
    }

    CornerTicks {
        anchors.fill: parent
    }
}
