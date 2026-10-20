// Wallpaper bench: the picker sheet on a mock desktop, using the real library
// (so the slides are the actual cache/thumbnails) with the centre slot on the
// fourth image, the applied badge on the second and the cycling footer forced
// on (after it hydrates, or the defaults overwrite it). Saves preview_wallpaper.
import QtQuick
import Quickshell
import Qt.labs.folderlistmodel
import qs.modules
import qs.modules.wallpaper

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#39434a"
        implicitWidth: 1000
        implicitHeight: 320

        // Guards the one-shot badge park below.
        property bool parked: false

        Item {
            id: scene

            anchors.centerIn: parent
            width: Theme.wallpaper.sheetWidth
            height: Theme.wallpaper.sheetHeight

            WallpaperSurface {
                anchors.fill: parent
            }

            WallpaperContent {
                id: content

                anchors.fill: parent
                anchors.margins: Theme.frame.margins
            }
        }

        // The cycling config arrives after the sheet is built; apply the preview
        // state once it has, or it would be overwritten by the defaults.
        Connections {
            target: WallpaperCycler

            function onHydratedChanged() {
                if (WallpaperCycler.hydrated) {
                    WallpaperCycler.enabled = true;
                    WallpaperCycler.shuffle = true;
                }
            }
        }

        Component.onCompleted: {
            // No state file writes from a preview.
            WallpaperService.mock = true;
            WallpaperCycler.mock = true;
            // The cycling config loads asynchronously and would overwrite these;
            // park the preview state after it has settled.
            Qt.callLater(function () {
                if (WallpaperCycler.hydrated) {
                    WallpaperCycler.enabled = true;
                    WallpaperCycler.shuffle = true;
                }
            });
            content.currentIndex = 3;
            Qt.callLater(win.park);
        }

        // Park the badge only once the service has settled. The listing arrives
        // asynchronously (`pathAt(1)` is empty this early, so adopt() would take
        // the *first* image) and the state file arrives later still; either one
        // can overwrite `current`, which is how the badge ended up on a slide
        // outside this shot (2026-10-19).
        function park() {
            if (win.parked || !WallpaperService.hydrated
                || WallpaperService.folder.status !== FolderListModel.Ready
                || WallpaperService.folder.count < 2)
                return;
            win.parked = true;
            WallpaperService.current = WallpaperService.pathAt(1);
        }

        Connections {
            target: WallpaperService.folder

            function onStatusChanged() {
                win.park();
            }

            function onCountChanged() {
                win.park();
            }
        }

        Connections {
            target: WallpaperService

            function onHydratedChanged() {
                win.park();
            }
        }

        Timer {
            interval: 900
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_wallpaper saved:", r.saveToFile("/tmp/opencode/preview_wallpaper.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
