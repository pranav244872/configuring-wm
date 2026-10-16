// Per-output lock surface: near-black backdrop, centered formation card.
// Clicking the backdrop refocuses the password field.
import QtQuick
import Quickshell.Wayland
import qs.modules
import qs.modules.lock

WlSessionLockSurface {
    id: root

    required property var lock
    required property LockAuth auth

    Rectangle {
        anchors.fill: parent
        color: "#080808"

        MouseArea {
            anchors.fill: parent
            onPressed: card.forceInputFocus()
        }
    }

    LockCard {
        id: card
        anchors.centerIn: parent
        width: 408
        height: card.implicitHeight
        auth: root.auth
    }

    Connections {
        target: root.lock
        function onSecureStateChanged() {
            if (root.lock.secure)
                card.forceInputFocus();
        }
    }

    Connections {
        target: root.auth
        function onFlashMsg() {
            card.forceInputFocus();
        }
    }

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: card.forceInputFocus()
    }
}
