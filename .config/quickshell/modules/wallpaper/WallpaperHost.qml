// Wallpaper picker: the filmstrip in a bottom sheet, built like DashboardHost
// (same slide, same dismiss rules) because the action is the same kind of
// thing -- rest on a bezel, get a panel.
//
// Opened by the bottom-right corner hot zone, SUPER+SHIFT+W, or
// `qs ipc call wallpaper toggle`; Escape or a click away closes it. Applying
// does *not* close it: the slides are the previews, so flipping through
// candidates and watching each one land behind the sheet is the point (the
// accent check marks the applied slide).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.lock
import qs.modules.wallpaper

PanelWindow {
    id: host

    property bool open: false

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

    onOpenChanged: if (host.open) content.activate()

    function show() {
        if (LockState.locked)
            return; // never open a surface behind the lock (see LockState.qml)
        host.open = true;
    }

    function close() {
        host.open = false;
    }

    function toggleVisible() {
        if (LockState.locked)
            return;
        host.open = !host.open;
    }

    // A lock started while the sheet was up: the hot zones cannot be trusted to
    // keep it closed, so close it here and unlock to a clean desktop.
    Connections {
        target: LockState

        function onLockedChanged() {
            if (LockState.locked)
                host.close();
        }
    }

    // Colours follow the wallpaper: Scheme regenerates the matugen palette when
    // the image changes. It reads the palette on disk at startup, so nothing is
    // regenerated when it is already current.
    function followWallpaper() {
        if (WallpaperService.mock)
            return; // a bench drives `current` itself; never generate from it
        Scheme.sync(WallpaperService.current);
    }

    Connections {
        target: WallpaperService

        function onCurrentChanged() {
            host.followWallpaper();
        }
    }

    Component.onCompleted: host.followWallpaper()

    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: host.open

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                host.close();
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                content.step(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                content.step(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // Keyboard parity with a click on the centred slide.
                content.applyCurrent();
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
            width: Theme.wallpaper.sheetWidth
            height: Theme.wallpaper.sheetHeight
            focus: true

            // Slide up from the bottom edge, same as the dashboard.
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

            WallpaperSurface {
                anchors.fill: parent
            }

            WallpaperContent {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                visible: host.open
            }
        }
    }

    IpcHandler {
        target: "wallpaper"

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

        function current(): string {
            return WallpaperService.current;
        }

        // Centre slot, so scripts and verification can assert position.
        function index(): int {
            return content.currentIndex;
        }

        function next(): void {
            content.step(1);
        }

        function prev(): void {
            content.step(-1);
        }

        function apply(): void {
            content.applyCurrent();
        }
    }
}
