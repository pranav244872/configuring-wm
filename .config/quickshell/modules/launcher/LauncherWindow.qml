// App launcher panel: left drawer sliding in on SUPER+F. Panel geometry is
// LauncherSurface (shared flare tokens); the content (search + list) lives in
// LauncherContent, shared with the preview benches.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules
import qs.modules.launcher

PanelWindow {
    id: host

    property bool open: false

    // Full screen overlay so clicking outside dismisses the launcher
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
        if (host.open) {
            content.clearSearch();
            focusTimer.restart();
        }
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

    // Give the text field real focus once the layer surface is up
    Timer {
        id: focusTimer
        interval: 40
        repeat: false
        onTriggered: {
            if (host.open)
                content.forceSearchFocus();
        }
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

        // Click outside dismisses
        MouseArea {
            id: dismissArea
            anchors.fill: parent
            enabled: host.open
            onClicked: host.close()
        }

        FocusScope {
            id: panel
            anchors.verticalCenter: parent.verticalCenter
            width: 400
            height: 520

            // Slide in from the left
            x: host.open ? 0 : -width - 20

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animation.enterDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.animation.curveOut
                }
            }

            // Keep clicks inside the panel out of dismissArea
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }

            LauncherSurface {
                anchors.fill: parent
            }

            LauncherContent {
                id: content
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 18
                anchors.topMargin: 40
                anchors.bottomMargin: 40

                onLaunch: (app) => {
                    app.execute();
                    host.close();
                }
                onDismissed: host.close()
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            host.open = !host.open;
        }

        function open(): void {
            host.open = true;
        }

        function close(): void {
            host.open = false;
        }
    }
}
