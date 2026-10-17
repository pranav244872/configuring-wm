// Dashboard: a bottom sheet holding the control sections. Narrower than the
// screen and a fixed share of its height, opened by the bottom-edge hot zone or
// `qs ipc call dashboard toggle`; Escape or a click away closes it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.dashboard

PanelWindow {
    id: host

    property bool open: false

    readonly property int sheetWidth: Theme.sizes.dashboardWidth
    readonly property int sheetHeight: Math.round(host.screen.height * Theme.sizes.dashboardHeightRatio)

    // Full-screen overlay so a click outside dismisses.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: host.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: host.open ? dismissArea : null
    }

    onOpenChanged: {
        if (host.open)
            content.activate();
        else
            content.deactivate();
    }

    function show() {
        host.open = true;
    }

    function close() {
        host.open = false;
    }

    function toggleVisible() {
        host.open = !host.open;
    }

    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: host.open

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                host.close();
                event.accepted = true;
            }
        }

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            enabled: host.open
            onClicked: host.close()
        }

        FocusScope {
            id: sheet

            anchors.horizontalCenter: parent.horizontalCenter
            width: host.sheetWidth
            height: host.sheetHeight
            focus: true

            // Slide up from the bottom edge. y stays unanchored so this binding
            // survives (same reason the launcher leaves its edge unanchored).
            y: host.open ? host.screen.height - height : host.screen.height + 20

            Behavior on y {
                NumberAnimation {
                    duration: host.open ? Theme.animation.enterDuration : Theme.animation.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: host.open ? Theme.animation.curveOut : Theme.animation.curveIn
                }
            }

            // Keep clicks inside the sheet out of dismissArea
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            DashboardSurface {
                anchors.fill: parent
            }

            DashboardContent {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                visible: host.open
            }
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            host.toggleVisible();
        }

        function open(): void {
            host.show();
        }

        function close(): void {
            host.close();
        }

        function isOpen(): bool {
            return host.open;
        }
    }
}
