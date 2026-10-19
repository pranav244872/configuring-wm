// Wallpaper bench: the picker sheet on a mock desktop, using the real library
// (so the slides are the actual files) with the centre slot on the fourth image
// and the applied badge parked on the second one. Saves preview_wallpaper.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.wallpaper

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#39434a"
        implicitWidth: 1000
        implicitHeight: 320

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

        Component.onCompleted: {
            // No state file writes from a preview.
            WallpaperService.mock = true;
            // The badge marks what is applied; the highlight sits elsewhere so
            // both states are visible in one shot.
            WallpaperService.current = WallpaperService.pathAt(1);
            content.currentIndex = 3;
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
