// Chaldea corner ticks: accent registration marks at the four corners of a
// hairline frame. Same size as the frame, sits on top.
import QtQuick
import qs.modules

Item {
    id: root

    property color tickColor: Theme.colors.primary
    property int arm: Theme.frame.tick
    property int weight: Theme.frame.line

    component Tick: Item {
        required property int hAlign // -1 left, 1 right
        required property int vAlign // -1 top, 1 bottom

        width: root.arm
        height: root.arm

        Rectangle {
            width: root.arm
            height: root.weight
            color: root.tickColor
            x: parent.hAlign < 0 ? 0 : parent.width - width
            y: parent.vAlign < 0 ? 0 : parent.height - height
        }

        Rectangle {
            width: root.weight
            height: root.arm
            color: root.tickColor
            x: parent.hAlign < 0 ? 0 : parent.width - width
            y: parent.vAlign < 0 ? 0 : parent.height - height
        }
    }

    Tick {
        anchors.left: parent.left
        anchors.top: parent.top
        hAlign: -1
        vAlign: -1
    }

    Tick {
        anchors.right: parent.right
        anchors.top: parent.top
        hAlign: 1
        vAlign: -1
    }

    Tick {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        hAlign: -1
        vAlign: 1
    }

    Tick {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hAlign: 1
        vAlign: 1
    }
}
