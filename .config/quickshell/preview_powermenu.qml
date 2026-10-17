// Power menu bench: the right drawer, open, over a mock desktop, with the
// hover fill pinned on one row (no pointer in a bench). Saves preview_powermenu.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.powermenu

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#ffffff"
        implicitWidth: 960
        implicitHeight: 640

        Item {
            id: scene
            anchors.fill: parent

            // Mock desktop so the drawer's layer0 surface reads
            Rectangle {
                anchors.fill: parent
                color: "#39434a"
            }

            Item {
                id: panel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.sizes.sessionWidth
                height: menuContent.implicitHeight + 2 * Theme.frame.margins

                PowerMenuSurface {
                    anchors.fill: parent
                }

                PowerMenuContent {
                    id: menuContent
                    anchors.fill: parent
                    anchors.margins: Theme.frame.margins
                    activeIndex: 1
                }
            }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_powermenu saved:", r.saveToFile("/tmp/opencode/preview_powermenu.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
