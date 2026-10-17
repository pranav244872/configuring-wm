// Session (power) menu: right drawer sliding in from the right bezel. Opened by
// the right-edge hot zone or `qs ipc call powermenu toggle`; closed by Escape,
// a click outside, or by running an entry.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.powermenu

PanelWindow {
    id: host

    property bool open: false

    readonly property int panelWidth: 300

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

    function show() {
        host.open = true;
    }

    function close() {
        host.open = false;
    }

    function toggleVisible() {
        host.open = !host.open;
    }

    function run(command) {
        Quickshell.execDetached(command);
        host.close();
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
            id: panel
            anchors.verticalCenter: parent.verticalCenter
            width: host.panelWidth
            // Sized to the menu content (content sits inset by frame margins).
            height: content.implicitHeight + 2 * Theme.frame.margins
            focus: true

            // Slide in from the right. No right anchor: anchoring would pin x
            // and kill this binding, leaving the drawer stuck on screen.
            x: host.open ? host.screen.width - width : host.screen.width + 20

            Behavior on x {
                NumberAnimation {
                    duration: host.open ? Theme.animation.enterDuration : Theme.animation.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: host.open ? Theme.animation.curveOut : Theme.animation.curveIn
                }
            }

            // Keep clicks inside the panel out of dismissArea
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            PowerMenuSurface {
                anchors.fill: parent
            }

            PowerMenuContent {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                visible: host.open

                onActivated: (command) => host.run(command)
                onDismissed: host.close()
            }
        }
    }

    IpcHandler {
        target: "powermenu"

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
