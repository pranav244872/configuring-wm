// Tray menu overlay: fullscreen click-catcher, menu panel anchored under
// the clicked icon. Esc / outside click / action closes it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.widgets
import qs.modules.bar

PanelWindow {
    id: host

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: TrayState.open
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: TrayState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: TrayState.open ? catcher : null
    }

    FocusScope {
        anchors.fill: parent
        focus: TrayState.open

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                TrayState.closeMenu();
                event.accepted = true;
            }
        }

        // Outside click dismisses (below the panel)
        MouseArea {
            id: catcher
            anchors.fill: parent
            onClicked: TrayState.closeMenu()
        }

        Rectangle {
            id: panel
            // Below the icon; flips above it when there is no room (tall
            // menu near the bottom edge). X follows the click, clamped in.
            x: Math.max(4, Math.min(host.width - width - 4, TrayState.anchorX))
            y: (TrayState.anchorY + height + 4 > host.height) ? Math.max(4, TrayState.anchorTop - height - 6) : Math.min(host.height - height - 4, TrayState.anchorY)
            width: 230
            height: menu.implicitHeight + 2
            color: Theme.colors.layer0
            border.width: Theme.frame.line
            border.color: Theme.colors.outline

            CornerTicks {
                anchors.fill: parent
            }

            TrayMenu {
                id: menu
                anchors.fill: parent
                anchors.margins: 1
                handle: TrayState.handle
                appTitle: TrayState.appTitle
                onDismissed: TrayState.closeMenu()
            }
        }
    }

    IpcHandler {
        target: "traymenu"

        function close(): void {
            TrayState.closeMenu();
        }
    }
}
