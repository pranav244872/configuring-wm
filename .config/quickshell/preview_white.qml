//@ pragma IconTheme Papirus
import QtQuick
import Quickshell
import qs.modules
import qs.modules.bar
import qs.modules.launcher
import qs.modules.osd

ShellRoot {
    PanelWindow {
        id: win
        visible: true
        color: "#ffffff"
        implicitWidth: 960
        implicitHeight: 560

        Item {
            id: scene
            anchors.fill: parent

            // Screen boundary outline
            Rectangle {
                anchors.fill: parent
                color: "#f8f9fa"
                border.width: 1
                border.color: "#d0d7de"
            }

            // 1. Top bar (real BarIsland, workspace 2 active)
            BarIsland {
                id: barRoot
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
            }

            // 2. Left launcher drawer (real surfaces, full height like production)
            Item {
                id: launcherDrawer
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 400

                LauncherSurface {
                    anchors.fill: parent
                }

                // Same margins LauncherWindow uses: 18 all round
                LauncherContent {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 18
                    anchors.bottomMargin: 18
                }
            }

            // 3. OSD preview (offset right so it doesn't cover the drawer in the bench)
            OsdIndicator {
                anchors.right: parent.right
                anchors.rightMargin: 60
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                label: "Volume"
                glyph: "volume_up"
                value: 0.65
                muted: false
                locked: false
            }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_white saved:", r.saveToFile("/tmp/opencode/preview_white.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
