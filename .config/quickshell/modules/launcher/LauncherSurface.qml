// Launcher drawer body: square full-height panel hugging the left bezel.
// No bezel-side borders; accent corner ticks only.
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.layer0
    }

    CornerTicks {
        anchors.fill: parent
    }
}
