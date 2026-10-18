// Network bar item bench: the item at rest in every state, plus the tooltip
// content it reveals on hover. The popup window itself can't be captured by
// grabToImage (it is a separate surface), so it is verified live with a real
// pointer -- see the notes. Saves preview_network.png
import QtQuick
import Quickshell
import qs.modules
import qs.modules.bar

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#2b3134"
        implicitWidth: 720
        implicitHeight: 560

        Column {
            id: scene
            anchors.centerIn: parent
            spacing: 10

            // Live: the real link, unmocked.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
            }

            // Connected, strong.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
                network.mock: true
                network.mockSsid: "pranav17"
                network.mockLevel: 1.0
            }

            NetworkTooltip {
                anchors.horizontalCenter: parent.horizontalCenter
                title: "pranav17"
                detail: "100% · WPA2 · 192.168.1.8"
            }

            // Connected, weak: one bar lit.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
                network.mock: true
                network.mockSsid: "pranav17"
                network.mockLevel: 0.25
            }

            // Captive portal / limited: the only state that warns.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
                network.mock: true
                network.mockSsid: "Airport_Free_WiFi"
                network.mockLevel: 0.75
                network.mockState: "portal"
            }

            NetworkTooltip {
                anchors.horizontalCenter: parent.horizontalCenter
                title: "Airport_Free_WiFi"
                detail: "75% · OPEN · 10.0.0.42"
                note: "PORTAL — SIGN IN TO GET ONLINE"
                titleColor: Theme.colors.warning
            }

            // Radio on, nothing connected.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
                network.mock: true
                network.mockState: "disconnected"
            }

            // Radio off.
            BarIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                activeWsIdOverride: 2
                network.mock: true
                network.mockState: "off"
            }

            NetworkTooltip {
                anchors.horizontalCenter: parent.horizontalCenter
                title: "WI-FI OFF"
                detail: "RADIO DISABLED"
            }
        }

        Timer {
            interval: 700
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_network saved:", r.saveToFile("/tmp/opencode/preview_network.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
