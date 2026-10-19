// Per-output lock surface: the wallpaper (blurred, scrimmed) with the centred
// formation card over it. Clicking anywhere refocuses the password field.
//
// The backdrop is a shared component, so the lock bench shows the same thing.
import QtQuick
import Quickshell.Wayland
import qs.modules
import qs.modules.lock

WlSessionLockSurface {
    id: root

    required property var lock
    required property LockAuth auth

    // The surface's own colour must be transparent: the toolkit default is
    // white, and the backdrop below paints the whole output.
    color: "transparent"

    LockBackdrop {
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent
        onPressed: card.forceInputFocus()
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
