// Do-not-disturb button.
//
// The bell-off glyph appears *only* while DND is on: the bar stays quiet when
// notifications behave normally and shows one thing when they are being held
// back, which is exactly when you want to know. Click toggles DND (the same
// one-click affordance as the caffeine button); the dashboard has the switch
// with the history next to it.
import QtQuick
import qs.modules
import qs.modules.widgets
import qs.modules.notifications

Item {
    id: root

    readonly property bool active: NotificationService.doNotDisturb

    visible: root.active

    implicitWidth: 22
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.colors.stateHover : "transparent"
    }

    Glyph {
        anchors.centerIn: parent
        text: Theme.glyphs.notifDnd
        color: Theme.colors.primary
        font.pixelSize: 16
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.toggleDnd()
    }
}
