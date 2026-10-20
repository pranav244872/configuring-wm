// Dashboard bench: two of the four tabs over a mock desktop -- the network
// tab with a mocked list (no radio involved) and the unsaved row expanded to
// show the passphrase prompt, and the notifications tab with a mocked history
// (timestamps included). Saves preview_dashboard.
import QtQuick
import Quickshell
import Quickshell.Networking
import qs.modules
import qs.modules.dashboard
import qs.modules.notifications

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#39434a"
        implicitWidth: 820
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
                // Preview of the connecting state: spinner + "CONNECTING…"
                name: "Harasu",
                signalStrength: 0.62,
                security: WifiSecurityType.Wpa2Psk,
                connected: false,
                known: false,
                state: ConnectionState.Connecting,
                stateChanging: true,
                address: ""
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

        component Sheet: Item {
            id: sheet

            required property int tab

            // The bench reaches in to mock the sections.
            property alias content: dashboardContent

            width: Theme.sizes.dashboardWidth
            height: Math.round(win.height * 0.36)

            DashboardSurface {
                anchors.fill: parent
            }

            DashboardContent {
                id: dashboardContent
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                currentTab: sheet.tab
            }
        }

        Column {
            id: scene
            anchors.centerIn: parent
            spacing: 18

            Sheet {
                id: networkSheet
                tab: 0
            }

            Sheet {
                id: notifSheet
                tab: 2
            }
        }

        // Feed the mocked data into the sections (overrides their live bindings).
        Component.onCompleted: {
            const net = networkSheet.content;
            net.network.mock = true;
            net.network.networks = win.mockNetworks;
            net.network.wifiEnabled = true;
            net.network.connectivity = NetworkConnectivity.Full;
            net.network.expandedSsid = "AirFiber-Prateek_EXT";
            // Show the scan sweep in the preview (does not touch the radio).
            net.activate();

            const now = Date.now();
            NotificationService.history = [
                {
                    notifId: 4,
                    app: "Firefox",
                    appIcon: "firefox",
                    summary: "Download complete",
                    body: "ubuntu-24.04-desktop-amd64.iso — 5.9 GB",
                    image: "",
                    urgency: 1,
                    expireTimeout: 0,
                    timestamp: now - 60000
                },
                {
                    notifId: 3,
                    app: "systemd",
                    appIcon: "",
                    summary: "Battery critically low",
                    body: "3% remaining. Plug in now — the session suspends at 2% unless a charger appears.",
                    image: "",
                    urgency: 2,
                    expireTimeout: 0,
                    timestamp: now - 900000
                },
                {
                    notifId: 2,
                    app: "Spotify",
                    appIcon: "",
                    summary: "Now playing",
                    body: "Aphex Twin — Xtal",
                    image: Quickshell.iconPath("audio-x-generic", true),
                    urgency: 0,
                    expireTimeout: 0,
                    timestamp: now - 1800000
                },
                {
                    notifId: 1,
                    app: "Slack",
                    appIcon: "",
                    summary: "Standup in 5",
                    body: "",
                    image: "",
                    urgency: 1,
                    expireTimeout: 0,
                    timestamp: now - 5400000
                }
            ];
        }

        Timer {
            interval: 700
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
