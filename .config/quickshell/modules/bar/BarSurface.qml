// Bar body: square island, 1px hairline border, accent corner ticks.
// Drawn by TopBar and the preview benches so geometry lives in one place.
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    implicitHeight: Theme.bar.height

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline
    }

    CornerTicks {
        anchors.fill: parent
    }
}
