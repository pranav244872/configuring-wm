import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../../qs/services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.exclusiveZone: -1
    color: "transparent"

    anchors {
        top: true
        right: true
        bottom: true
    }

    margins {
        top: 40
        right: 0
    }

    implicitWidth: 350

    // KEY FIX: hide the window entirely when there are no popups.
    // Without this, a 350px-wide invisible layershell surface sits permanently
    // on the right side of the screen swallowing all mouse clicks.
    visible: NotifService.popups.length > 0

    ListView {
        id: popupList
        anchors.fill: parent
        spacing: 0
        clip: true

        model: ScriptModel {
            values: NotifService.popups
        }

        delegate: NotificationCard {}

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 350; to: 0; duration: 300; easing.type: Easing.OutBack }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 200 }
            NumberAnimation { property: "x"; to: 100; duration: 200 }
        }

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutQuad }
        }
    }
}
