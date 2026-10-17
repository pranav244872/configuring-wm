// Network section: the wifi switch, a scanning list of networks, and the
// connect / passphrase / forget flows.
//
// Scanning is quickshell's `scannerEnabled`, which drives a rate-limited
// periodic `RequestScan` (nm/wireless.cpp); stopping it leaves the access-point
// list intact, so we only scan while the dashboard is open.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.modules
import qs.modules.widgets
import qs.modules.dashboard
import "network_list.js" as Net

Item {
    id: root

    // Settable defaults so the bench can inject a mock list (no radio needed).
    property var networks: Net.sortNetworks(root.device ? root.device.networks.values : [])
    property bool wifiEnabled: Networking.wifiEnabled
    property int connectivity: Networking.connectivity

    property string expandedSsid: ""
    property string errorText: ""

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool portal: root.connectivity === NetworkConnectivity.Portal

    // Spinner window: the rescan glyph turns while a fresh scan is requested.
    // NM's own scan state is not exposed, so this is a bounded affordance.
    readonly property bool spinning: spinTimer.running

    function activate() {
        if (root.device)
            root.device.scannerEnabled = true;
        spinTimer.restart();
    }

    function deactivate() {
        if (root.device)
            root.device.scannerEnabled = false;
        spinTimer.stop();
        root.expandedSsid = "";
        root.errorText = "";
    }

    function rescan() {
        // Restart the scan cycle: dropping the flag stops quickshell's scan
        // timer, so flip it back on the next tick.
        if (!root.device)
            return;
        root.device.scannerEnabled = false;
        rescanTimer.restart();
        spinTimer.restart();
    }

    function failText(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "WRONG PASSWORD";
        case ConnectionFailReason.WifiAuthTimeout:
            return "AUTH TIMED OUT — CHECK THE PASSWORD";
        case ConnectionFailReason.WifiClientDisconnected:
            return "DISCONNECTED — CHECK THE PASSWORD";
        case ConnectionFailReason.WifiNetworkLost:
            return "NETWORK OUT OF RANGE";
        default:
            return "CONNECTION FAILED";
        }
    }

    Timer {
        id: rescanTimer
        interval: 60
        onTriggered: if (root.device) root.device.scannerEnabled = true
    }

    Timer {
        id: spinTimer
        // Covers the observed NM scan latency (~6s) so the header shows that a
        // refresh is in flight while the list is still filling.
        interval: 6000
    }

    component Rule: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.frame.line
        color: Theme.colors.outline
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ---------------- header ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                text: "NETWORK"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.wifiEnabled
                text: root.networks.length.toString().padStart(2, "0")
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.primary
            }

            StyledText {
                id: scanGlyph
                Layout.alignment: Qt.AlignVCenter
                text: Theme.glyphs.wifiScan
                font.family: Theme.font.icon
                font.pixelSize: 18
                color: scanMa.containsMouse ? Theme.colors.primary : Theme.colors.subtext
                opacity: root.wifiEnabled ? 1 : 0.35

                RotationAnimator on rotation {
                    running: root.spinning && root.wifiEnabled
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }

                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    enabled: root.wifiEnabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.rescan()
                }
            }

            Toggle {
                Layout.alignment: Qt.AlignVCenter
                checked: root.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }

        Rule {
        }

        // ---------------- body ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Wi-Fi off
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: !root.wifiEnabled

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.glyphs.wifiOff
                    font.family: Theme.font.icon
                    font.pixelSize: 30
                    color: Theme.colors.subtext
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "WI-FI IS OFF"
                    font.pixelSize: Theme.font.size.sm
                    font.letterSpacing: Theme.frame.tracking
                    color: Theme.colors.subtext
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: onLabel.implicitWidth + 24
                    height: 26
                    radius: 0
                    color: onMa.containsMouse ? Theme.colors.primary : "transparent"
                    border.width: Theme.frame.line
                    border.color: Theme.colors.primary

                    StyledText {
                        id: onLabel
                        anchors.centerIn: parent
                        text: "TURN ON"
                        font.pixelSize: Theme.frame.labelSize
                        font.letterSpacing: Theme.frame.tracking
                        color: onMa.containsMouse ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
                    }

                    MouseArea {
                        id: onMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Networking.wifiEnabled = true
                    }
                }
            }

            // Network list
            ListView {
                id: list
                anchors.fill: parent
                visible: root.wifiEnabled
                clip: true
                spacing: 2
                topMargin: 4
                bottomMargin: 4

                model: root.networks

                delegate: NetworkRow {
                    required property var modelData
                    required property int index

                    width: list.width
                    net: modelData
                    expanded: root.expandedSsid === modelData.name
                    errorText: root.expandedSsid === modelData.name ? root.errorText : ""

                    // An expansion can be taller than the leftover space.
                    function reveal() {
                        list.positionViewAtIndex(index, ListView.Contain);
                    }

                    onToggleExpanded: {
                        if (root.expandedSsid === modelData.name) {
                            root.expandedSsid = "";
                            root.errorText = "";
                        } else {
                            root.expandedSsid = modelData.name;
                            root.errorText = "";
                        }
                        reveal();
                    }

                    onConnectRequested: {
                        root.errorText = "";
                        root.expandedSsid = "";
                        modelData.connect();
                    }

                    onPskSubmitted: (psk) => {
                        root.errorText = "";
                        modelData.connectWithPsk(psk);
                    }

                    onDisconnectRequested: {
                        root.expandedSsid = "";
                        modelData.disconnect();
                    }

                    onForgetRequested: {
                        root.expandedSsid = "";
                        modelData.forget();
                    }

                    onFailed: (reason) => {
                        // Surface the reason on the row that failed, even for a
                        // saved network (e.g. a changed passphrase).
                        root.errorText = root.failText(reason);
                        root.expandedSsid = modelData.name;
                        reveal();
                    }
                }

                // Empty state
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: list.count === 0

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.glyphs.wifiFind
                        font.family: Theme.font.icon
                        font.pixelSize: 28
                        color: Theme.colors.subtext
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "NO NETWORKS FOUND"
                        font.pixelSize: Theme.font.size.sm
                        font.letterSpacing: Theme.frame.tracking
                        color: Theme.colors.subtext
                    }
                }
            }
        }

        // Captive portal hint
        StyledText {
            Layout.fillWidth: true
            visible: root.wifiEnabled && root.portal
            text: "CAPTIVE PORTAL — SIGN IN TO GET ONLINE"
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
            color: Theme.colors.warning
        }
    }
}
