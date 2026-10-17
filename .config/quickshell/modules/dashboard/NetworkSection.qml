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

    // The list is a *snapshot*, not a live binding: rebuilding it on every
    // property change (signal strengths tick during a scan) reorders rows and
    // resets delegates mid-edit. Both reference applets avoid this -- plasma-nm
    // freezes its model with setDelayModelUpdates() while the password field is
    // open, nm-applet reuses its menu items by hash. The network objects stay
    // live; only order/membership is frozen.
    property var networks: []
    property bool wifiEnabled: Networking.wifiEnabled
    property int connectivity: Networking.connectivity

    // Bench hook: a mocked list must not be clobbered by the live refresh.
    property bool mock: false

    // Sheet visibility (set by DashboardContent); the refresh below only runs
    // while open.
    property bool active: false

    property string expandedSsid: ""
    property string errorText: ""
    property string pskDraft: ""

    readonly property bool editing: root.expandedSsid.length > 0

    onEditingChanged: if (!root.editing) root.rebuild()

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool portal: root.connectivity === NetworkConnectivity.Portal

    // Spinner window: the rescan glyph turns while a fresh scan is requested.
    // NM's own scan state is not exposed, so this is a bounded affordance.
    readonly property bool spinning: spinTimer.running

    // Recompute the snapshot. `force` bypasses the identical-snapshot check
    // (used when the sheet opens); a normal refresh never runs while a prompt is
    // open, so typing is never disturbed.
    function rebuild(force) {
        if (root.mock)
            return;
        if (!force && root.editing)
            return;
        const next = Net.sortNetworks(root.device ? root.device.networks.values : []);
        if (!force && Net.sameOrder(next, root.networks))
            return;
        root.networks = next;
    }

    function activate() {
        if (root.device)
            root.device.scannerEnabled = true;
        root.active = true;
        root.rebuild(true);
        spinTimer.restart();
    }

    function deactivate() {
        if (root.device)
            root.device.scannerEnabled = false;
        root.active = false;
        spinTimer.stop();
        root.expandedSsid = "";
        root.errorText = "";
        root.pskDraft = "";
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

    // Membership changes arrive as model signals. Rebuild on those instead of
    // waiting for the 1s refresh, so a removed AP cannot linger as a dead
    // wrapper; the 150ms debounce collapses a scan burst into one rebuild.
    Timer {
        id: modelChangedTimer
        interval: 150
        onTriggered: root.rebuild()
    }

    Connections {
        target: root.device ? root.device.networks : null

        function onObjectInsertedPost() {
            modelChangedTimer.restart();
        }

        function onObjectRemovedPost() {
            modelChangedTimer.restart();
        }
    }

    // Membership/order refresh while the sheet is open. 1s is well under NM's
    // scan cadence and costs one small in-memory sort.
    Timer {
        interval: 1000
        repeat: true
        running: root.active && root.wifiEnabled
        onTriggered: root.rebuild()
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
                    draft: root.pskDraft
                    deviceAddress: root.device ? root.device.address : ""
                    expanded: root.expandedSsid === modelData.name
                    errorText: root.expandedSsid === modelData.name ? root.errorText : ""

                    // An expansion can be taller than the leftover space.
                    function reveal() {
                        list.positionViewAtIndex(index, ListView.Contain);
                    }

                    onDraftEdited: (text) => root.pskDraft = text

                    onToggleExpanded: {
                        root.pskDraft = "";
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
                        root.pskDraft = "";
                        modelData.connect();
                    }

                    onPskSubmitted: (psk) => {
                        root.errorText = "";
                        // Close the prompt (the row shows its spinner); the draft
                        // is kept so a failure reopens with the text to fix.
                        root.expandedSsid = "";
                        modelData.connectWithPsk(psk);
                    }

                    onDisconnectRequested: {
                        root.expandedSsid = "";
                        root.pskDraft = "";
                        modelData.disconnect();
                    }

                    onForgetRequested: {
                        root.expandedSsid = "";
                        root.pskDraft = "";
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
