// Keep-awake button: toggles Caffeine, which inhibits idle so the session
// never locks / blanks / suspends. Coffee icon lit while active.
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    readonly property bool active: Caffeine.enabled

    implicitWidth: 22
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.colors.stateHover : "transparent"
    }

    Glyph {
        anchors.centerIn: parent
        text: Theme.glyphs.caffeine
        color: root.active ? Theme.colors.primary : ColorUtils.transparentize(Theme.colors.fgLayer1, 0.45)
        font.pixelSize: 16
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Caffeine.toggle()
    }
}
