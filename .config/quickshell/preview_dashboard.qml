// Dashboard bench: the bottom sheet over a mock desktop, with a mocked network
// list so no radio is involved. The secured + unsaved row is expanded to show
// the passphrase prompt. Saves preview_dashboard.
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.modules
import qs.modules.dashboard

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#ffffff"
        implicitWidth: 960
        implicitHeight: 900

        readonly property var mockNetworks: [
            {
                name: "pranav17",
                signalStrength: 1.0,
                security: WifiSecurityType.Wpa2Psk,
                connected: true,
                known: true,
                state: ConnectionState.Connected,
                stateChanging: false,
                address: "192.168.1.4"
            },
            {
                name: "Harasu_5G",
                signalStrength: 0.57,
                security: WifiSecurityType.Wpa2Psk,
                connected: false,
                known: true,
                state: ConnectionState.Disconnected,
                stateChanging: false,
                address: ""
            },
            {
                name: "AirFiber-Prateek_EXT",
                signalStrength: 0.40,
                security: WifiSecurityType.Wpa2Psk,
                connected: false,
                known: false,
                state: ConnectionState.Disconnected,
                stateChanging: false,
                address: ""
            },
            {
                name: "VINOD C",
                signalStrength: 0.22,
                security: WifiSecurityType.Wpa2Psk,
                connected: false,
                known: false,
                state: ConnectionState.Disconnected,
                stateChanging: false,
                address: ""
            },
            {
                name: "Cafe_Guest",
                signalStrength: 0.30,
                security: WifiSecurityType.Open,
                connected: false,
                known: false,
                state: ConnectionState.Disconnected,
                stateChanging: false,
                address: ""
            }
        ]

        Item {
            id: scene
            anchors.fill: parent

            // Mock desktop so the sheet's surface reads
            Rectangle {
                anchors.fill: parent
                color: "#39434a"
            }

            Item {
                id: sheet

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: Theme.sizes.dashboardWidth
                height: Math.round(parent.height * Theme.sizes.dashboardHeightRatio)

                DashboardSurface {
                    anchors.fill: parent
                }

                DashboardContent {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Theme.frame.margins
                }
            }
        }

        // Feed the mocked list into the section (overrides its live binding).
        Component.onCompleted: {
            content.network.mock = true;
            content.network.networks = mockNetworks;
            content.network.wifiEnabled = true;
            content.network.connectivity = NetworkConnectivity.Full;
            content.network.expandedSsid = "AirFiber-Prateek_EXT";
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_dashboard saved:", r.saveToFile("/tmp/opencode/preview_dashboard.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
