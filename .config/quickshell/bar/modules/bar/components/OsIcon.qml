// OsIcon.qml — Arch Linux logo that opens the launcher
//
// Uses Arch Linux Nerd Font icon on the far left of the bar.
// Clicking it opens the launcher shell.

import QtQuick
import Quickshell

Item {
    id: root

    required property var colors

    implicitWidth: 28
    implicitHeight: 28

    // Arch Linux logo from Nerd Font
    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 2 // Fine-tune vertical centering for this glyph
        text: "\uf303" // nf-linux-archlinux
        color: colors.m3.tertiary
        font.pixelSize: 22
        font.family: "JetBrainsMono Nerd Font Propo"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Qt.inputMethod.hide()
            Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
        }
    }
}
