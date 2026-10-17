// Power menu body: square framed panel, right side of the screen. Unlike the
// launcher (flush against a bezel) this one floats, so it carries the full
// Chaldea hairline frame + accent corner ticks, like CalendarCard.
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
