// Visual test bench: bar states + all OSD states, dark background.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.osd
import qs.modules.bar

ShellRoot {
    PanelWindow {
        id: win
        visible: true
        color: "#2b3134"
        implicitWidth: 380
        implicitHeight: 480

        Column {
            id: scene
            anchors.centerIn: parent
            spacing: 14

            // Bar with active workspace 10 (dynamic >5 chip appended)
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 10
            }

            // Bar with active workspace 2
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
            }

            OsdIndicator {
                label: "Volume"
                glyph: Icons.volume(0.15, false)
                value: 0.15
            }

            OsdIndicator {
                label: "Volume"
                glyph: Icons.volume(0.45, false)
                value: 0.45
            }

            OsdIndicator {
                label: "Muted"
                glyph: Icons.volume(0.45, true)
                value: 0.45
                muted: true
            }

            OsdIndicator {
                label: "Brightness"
                glyph: Icons.brightness(0.55)
                value: 0.55
            }
        }

        Timer {
            running: true
            interval: 700
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview saved:", r.saveToFile("/tmp/opencode/preview.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
