import QtQuick
import Quickshell
import qs.modules
import qs.modules.bar

PanelWindow {
    id: bar

    anchors {
        top: true
    }

    // Push tiled windows down: 18 + gaps_out 20 - height 30 = 8px window gap
    exclusiveZone: 18

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
