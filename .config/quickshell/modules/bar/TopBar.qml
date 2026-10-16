import QtQuick
import Quickshell
import qs.modules
import qs.modules.bar

PanelWindow {
    id: bar

    anchors {
        top: true
    }

    // Push tiled windows down: zone reserves exactly the bar height, so the
    // bar gap always equals gaps_out (30 + 12 - 30 = 12px, same as edges)
    exclusiveZone: 30

    implicitWidth: island.implicitWidth
    implicitHeight: island.implicitHeight
    color: "transparent"

    mask: Region {
        item: island
        intersection: bar.visible ? Intersection.Combine : Intersection.Xor
    }

    BarIsland {
        id: island
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
