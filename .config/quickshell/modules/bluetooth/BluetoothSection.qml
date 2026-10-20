// Bluetooth section of the dashboard. A study of Blueberry's UX (which is a
// wrapper around gnome-bluetooth) rebuilt in the Chaldea frame: one toggle,
// explicit states for no-adapter / rfkill-blocked / powered-off, a saved list
// and a "just discovered" list, and an inline detail area instead of a second
// page.
//
// BlueZ is reached through Quickshell.Bluetooth (native, no bluetoothctl
// parsing). Quickshell registers no pairing agent, so pairing runs a
// short-lived `bluetoothctl --agent NoInputNoOutput`: BlueZ then auto-confirms
// JustWorks/numeric-comparison requests. PIN-only devices have to be paired
// once from a terminal -- documented in notes/bluetooth.md.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.modules
import qs.modules.widgets
import qs.modules.bluetooth
import "bluetooth_model.js" as Bt

Item {
    id: root

    // Sheet visibility, set by DashboardContent; everything (scan, probes)
    // only runs while this tab is the visible one.
    property bool active: false

    // Bench hooks: plain objects, and no process is started in mock mode.
    property bool mock: false
    property var mockAdapter: null
    property var mockDevices: []
    property var mockRfkill: ({ soft: false, hard: false })

    readonly property var adapter: root.mock ? root.mockAdapter : Bluetooth.defaultAdapter
    readonly property bool available: !!root.adapter
    readonly property bool enabled: root.available && !!root.adapter.enabled
    readonly property bool discovering: root.available && !!root.adapter.discovering
    readonly property bool discoverable: root.available && !!root.adapter.discoverable
    readonly property bool blocked: root.available && root.adapter.state === BluetoothAdapterState.Blocked
    readonly property bool actionEnabled: root.available && !(root.blocked && root.hardBlocked)

    // rfkill detail: native state only says "Blocked"; the copy differs between
    // a software block (fixable) and a hardware switch (not fixable in software).
    property bool softBlocked: false
    property bool hardBlocked: false
    property bool wantPower: false

    property string alias: ""
    property var devices: []
    property var rows: []
    property string signature: ""
    property string expandedAddress: ""
    property string errorText: ""
    property string errorAddress: ""

    // Pending operation watcher: { address, kind, started }.
    property var pending: null
    property var pendingPair: null
    property bool agentWanted: false
    property bool agentReady: false

    property string aliasDraft: ""
    property bool aliasEditing: false

    // ---------------------------------------------------------------- model

    function sourceDevices() {
        if (root.mock)
            return root.mockDevices || [];
        return root.available && root.adapter.devices ? root.adapter.devices.values : [];
    }

    // Snapshot rebuild. Only when membership/order changes, so a live state
    // tick cannot reset a delegate mid-interaction (the network list's rule).
    function rebuild(force) {
        const next = Bt.sorted(root.sourceDevices());
        const sig = Bt.signature(next);
        if (!force && sig === root.signature)
            return;
        root.signature = sig;
        root.devices = next;
        root.rows = Bt.rows(next);
    }

    // ---------------------------------------------------------- lifecycle

    function activate() {
        root.active = true;
        root.clearError();
        if (root.mock) {
            root.alias = root.mockAdapter ? String(root.mockAdapter.name || "") : "";
            root.softBlocked = !!root.mockRfkill.soft;
            root.hardBlocked = !!root.mockRfkill.hard;
            root.rebuild(true);
            return;
        }
        root.rebuild(true);
        root.refreshRfkill();
        root.refreshAlias();
        if (root.enabled)
            root.adapter.discovering = true;
    }

    function deactivate() {
        root.active = false;
        root.expandedAddress = "";
        root.aliasEditing = false;
        root.clearError();
        if (!root.mock && root.available && root.enabled)
            root.adapter.discovering = false;
        if (!root.pending)
            root.stopAgent();
    }

    function rescan() {
        if (root.mock || !root.available || !root.enabled)
            return;
        root.adapter.discovering = false;
        rescanTimer.restart();
    }

    function setEnabled(on) {
        root.clearError();
        if (root.mock) {
            if (root.mockAdapter) {
                root.mockAdapter.enabled = on;
                root.mockAdapter.discovering = on;
            }
            root.rebuild(true);
            return;
        }
        if (!root.available)
            return;
        if (!on) {
            root.adapter.enabled = false;
            return;
        }
        if (root.blocked) {
            root.unblock();
            return;
        }
        root.adapter.enabled = true;
    }

    function unblock() {
        root.clearError();
        if (root.mock) {
            if (root.mockAdapter) {
                root.mockAdapter.state = BluetoothAdapterState.Enabled;
                root.mockAdapter.enabled = true;
            }
            root.softBlocked = false;
            root.hardBlocked = false;
            root.rebuild(true);
            return;
        }
        root.wantPower = true;
        rfkillUnblock.running = true;
        unblockGuard.restart();
    }

    function toggleDiscoverable() {
        if (root.mock || !root.enabled)
            return;
        root.adapter.discoverableTimeout = 180;
        root.adapter.discoverable = !root.adapter.discoverable;
    }

    // ------------------------------------------------------------ rfkill

    function refreshRfkill() {
        if (root.mock)
            return;
        rfkillProbe.running = true;
    }

    function applyRfkill(text) {
        let soft = false;
        let hard = false;
        try {
            const data = JSON.parse(text);
            for (const entry of (data.rfkilldevices || [])) {
                const name = String(entry.device || "");
                if (name.indexOf("bluetooth") < 0 && name.indexOf("hci") !== 0)
                    continue;
                if (String(entry.soft) === "blocked")
                    soft = true;
                if (String(entry.hard) === "blocked")
                    hard = true;
            }
        } catch (e) {
            return; // unparsable: keep the last known values instead of guessing
        }
        root.softBlocked = soft;
        root.hardBlocked = hard;
    }

    // ------------------------------------------------------------- alias

    function refreshAlias() {
        if (root.mock)
            return;
        aliasProbe.running = true;
    }

    function beginAliasEdit() {
        if (root.mock || !root.enabled)
            return;
        root.aliasDraft = root.alias;
        root.aliasEditing = true;
        aliasFocus.restart();
    }

    function commitAlias() {
        const name = root.aliasDraft.trim();
        root.aliasEditing = false;
        if (name.length === 0 || name === root.alias)
            return;
        root.alias = name;
        if (root.mock)
            return;
        aliasSet.command = ["bluetoothctl", "system-alias", name];
        aliasSet.running = true;
    }

    // ------------------------------------------------------------ actions

    function pair(dev) {
        if (root.mock || !dev)
            return;
        root.clearError();
        root.expandedAddress = dev.address;
        root.pending = { address: dev.address, kind: "pair", started: Date.now() };

        if (agent.running && root.agentReady) {
            dev.pair();
            return;
        }
        root.pendingPair = dev;
        root.agentWanted = true;
        agentFallback.restart();
        agentIdle.restart();
    }

    function cancelPair(dev) {
        if (root.mock || !dev)
            return;
        if (dev.pairing)
            dev.cancelPair();
        root.pending = null;
        root.stopAgent();
    }

    function connect(dev) {
        if (root.mock || !dev)
            return;
        root.clearError();
        root.pending = { address: dev.address, kind: "connect", started: Date.now() };
        dev.connect();
    }

    function disconnect(dev) {
        if (root.mock || !dev)
            return;
        dev.disconnect();
    }

    function forget(dev) {
        if (root.mock || !dev)
            return;
        if (root.expandedAddress === dev.address)
            root.expandedAddress = "";
        root.pending = null;
        dev.forget();
    }

    // ------------------------------------------------------------- errors

    function clearError() {
        root.errorText = "";
        root.errorAddress = "";
        errorTimer.stop();
    }

    function fail(text, address) {
        root.errorText = text;
        root.errorAddress = address || "";
        errorTimer.restart();
    }

    // pair()/connect() are fire-and-forget in Quickshell, so completion is
    // inferred from the device's own state -- and so is failure (state went
    // back to idle without connecting/paired).
    function watchPending() {
        const p = root.pending;
        if (!p)
            return;
        const dev = root.devices.find(d => d.address === p.address);
        if (!dev) {
            root.pending = null;
            return;
        }
        const elapsed = Date.now() - p.started;

        if (p.kind === "pair") {
            if (dev.pairing)
                return;
            if (dev.paired) {
                dev.trusted = true;
                root.pending = null;
                root.stopAgent();
                return;
            }
            if (elapsed > 1200) {
                root.pending = null;
                root.fail("PAIRING FAILED — PUT THE DEVICE IN PAIRING MODE AND RETRY", dev.address);
                root.stopAgent();
            }
            return;
        }

        if (dev.connected) {
            root.pending = null;
            return;
        }
        if (elapsed > 1200 && dev.state === BluetoothDeviceState.Disconnected) {
            root.pending = null;
            root.fail("CONNECTION FAILED", dev.address);
        } else if (elapsed > 20000) {
            root.pending = null;
            root.fail("CONNECTION TIMED OUT", dev.address);
        }
    }

    function agentText(text) {
        if (!root.agentWanted || root.agentReady)
            return;
        if (String(text).indexOf("Agent registered") < 0)
            return;
        root.agentReady = true;
        agentFallback.stop();
        if (root.pendingPair) {
            const dev = root.pendingPair;
            root.pendingPair = null;
            dev.pair();
        }
    }

    function stopAgent() {
        root.agentWanted = false;
        root.agentReady = false;
        root.pendingPair = null;
        if (agent.running)
            agent.signal(15);
        agentIdle.stop();
        agentFallback.stop();
    }

    // -------------------------------------------------------------- timers

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: true
        running: root.active && root.enabled
        onTriggered: root.rebuild()
    }

    Timer {
        id: modelChangedTimer
        interval: 150
        onTriggered: root.rebuild()
    }

    Connections {
        target: root.mock ? null : (root.available ? root.adapter.devices : null)

        function onObjectInsertedPost() {
            modelChangedTimer.restart();
        }

        function onObjectRemovedPost() {
            modelChangedTimer.restart();
        }
    }

    Timer {
        id: rfkillTimer
        interval: 2000
        repeat: true
        running: root.active && root.blocked
        onTriggered: root.refreshRfkill()
    }

    Timer {
        id: pendingTimer
        interval: 500
        repeat: true
        running: root.active && root.pending !== null
        onTriggered: root.watchPending()
    }

    Timer {
        id: rescanTimer
        interval: 80
        onTriggered: if (!root.mock && root.available && root.enabled) root.adapter.discovering = true
    }

    Timer {
        id: errorTimer
        interval: 6000
        onTriggered: root.clearError()
    }

    Timer {
        id: aliasFocus
        interval: 60
        onTriggered: if (root.aliasEditing) aliasField.forceActiveFocus()
    }

    Timer {
        id: agentFallback
        interval: 1500
        onTriggered: {
            if (root.pendingPair) {
                const dev = root.pendingPair;
                root.pendingPair = null;
                dev.pair();
            }
        }
    }

    Timer {
        id: agentIdle
        interval: 15000
        onTriggered: {
            if (root.pending) {
                root.pending = null;
                root.fail("PAIRING TIMED OUT");
            }
            root.stopAgent();
        }
    }

    Timer {
        id: unblockGuard
        interval: 2500
        onTriggered: if (root.blocked) {
            root.wantPower = false;
            root.fail("STILL BLOCKED — CHECK THE HARDWARE SWITCH");
        }
    }

    Timer {
        id: powerTick
        interval: 400
        onTriggered: {
            root.refreshRfkill();
            if (root.available && !root.blocked && !root.adapter.enabled)
                root.adapter.enabled = true;
        }
    }

    onBlockedChanged: {
        if (!root.blocked && root.wantPower && root.available) {
            root.adapter.enabled = true;
            root.wantPower = false;
            unblockGuard.stop();
        }
    }

    // ------------------------------------------------------------ processes

    Process {
        id: rfkillProbe
        command: ["rfkill", "-J", "-o", "SOFT,HARD,DEVICE"]
        stdout: StdioCollector {
            id: rfkillOut
            onStreamFinished: root.applyRfkill(rfkillOut.text)
        }
    }

    Process {
        id: rfkillUnblock
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: (code, status) => {
            if (code !== 0) {
                root.wantPower = false;
                root.fail("COULD NOT UNBLOCK — CHECK RFKILL PERMISSIONS");
                return;
            }
            root.refreshRfkill();
            powerTick.restart();
        }
    }

    Process {
        id: aliasProbe
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            id: aliasOut
            onStreamFinished: {
                const m = /^\s*Alias:\s*(.+)$/m.exec(aliasOut.text);
                if (m)
                    root.alias = m[1].trim();
            }
        }
    }

    Process {
        id: aliasSet
        command: ["bluetoothctl", "system-alias", ""]
        onExited: root.refreshAlias()
    }

    // The pairing agent. stdinEnabled keeps bluetoothctl alive without a TTY;
    // it stays registered until we SIGTERM it after the pairing settles.
    Process {
        id: agent
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        stdinEnabled: true
        running: root.agentWanted
        stdout: StdioCollector {
            id: agentOut
            onTextChanged: root.agentText(agentOut.text)
        }
        onExited: {
            root.agentReady = false;
        }
    }

    // ------------------------------------------------------------------- ui

    // A tracked section rule, the same language as the tab row's hairline.
    component SectionHeader: Item {
        id: sh

        property string label: ""
        property int count: 0

        implicitHeight: 26

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: sh.label
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            StyledText {
                text: String(sh.count).padStart(2, "0")
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.primary
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.frame.line
            color: Theme.colors.outline
        }
    }

    // Centred state panel, shared by no-adapter / blocked / off.
    component EmptyState: Column {
        id: state

        property string glyph: Theme.glyphs.btOff
        property string title: ""
        property string hint: ""
        property string action: ""

        signal actionTriggered()

        anchors.centerIn: parent
        spacing: 8

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: state.glyph
            font.family: Theme.font.icon
            font.pixelSize: 30
            color: Theme.colors.subtext
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: state.title
            font.pixelSize: Theme.font.size.sm
            font.letterSpacing: Theme.frame.tracking
            color: Theme.colors.subtext
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: state.hint.length > 0
            text: state.hint
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
            color: Theme.colors.subtext
            opacity: 0.7
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: state.action.length > 0
            width: actionLabel.implicitWidth + 24
            height: 26
            radius: 0
            color: actionMa.containsMouse ? Theme.colors.primary : "transparent"
            border.width: Theme.frame.line
            border.color: Theme.colors.primary

            StyledText {
                id: actionLabel
                anchors.centerIn: parent
                text: state.action
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: actionMa.containsMouse ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
            }

            MouseArea {
                id: actionMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: state.actionTriggered()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ---------------- header ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Toggle {
                Layout.alignment: Qt.AlignVCenter
                checked: root.enabled
                enabled: root.actionEnabled
                opacity: root.actionEnabled ? 1 : 0.35
                onToggled: root.setEnabled(!root.enabled)
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: "BLUETOOTH"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.enabled
                text: String(root.devices.length).padStart(2, "0")
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.enabled
                text: Theme.glyphs.btScan
                font.family: Theme.font.icon
                font.pixelSize: 18
                color: scanMa.containsMouse ? Theme.colors.primary : Theme.colors.subtext
                opacity: root.enabled ? 1 : 0.35

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animation.valueDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.animation.curveOut
                    }
                }

                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    enabled: root.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.rescan()
                }
            }
        }

        // Hairline rule that doubles as the discovery track: while the adapter
        // is scanning an accent segment sweeps across it.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.frame.line
                color: Theme.colors.outline
            }

            Rectangle {
                id: scanSweep

                width: parent.width * 0.28
                height: 2
                color: Theme.colors.primary
                opacity: root.discovering && root.enabled ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animation.valueDuration
                    }
                }

                NumberAnimation on x {
                    running: root.discovering && root.enabled
                    from: -scanSweep.width
                    to: scanSweep.parent.width
                    duration: 1100
                    loops: Animation.Infinite
                    easing.type: Easing.InOutSine
                }
            }
        }

        // ---------------- body ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // No adapter at all
            EmptyState {
                visible: !root.available
                glyph: Theme.glyphs.btOff
                title: "NO BLUETOOTH ADAPTER"
            }

            // rfkill block. Blueberry's two copies, kept apart because only one
            // of them is actionable.
            EmptyState {
                visible: root.available && root.blocked
                glyph: Theme.glyphs.btOff
                title: root.hardBlocked ? "DISABLED BY HARDWARE SWITCH" : "BLUETOOTH IS BLOCKED (RFKILL)"
                hint: root.hardBlocked ? "TURN IT ON WITH THE LAPTOP'S WIRELESS SWITCH" : ""
                action: root.hardBlocked ? "" : "UNBLOCK"
                onActionTriggered: root.unblock()
            }

            // Powered off
            EmptyState {
                visible: root.available && !root.blocked && !root.enabled
                glyph: Theme.glyphs.btOff
                title: "BLUETOOTH IS OFF"
                action: "TURN ON"
                onActionTriggered: root.setEnabled(true)
            }

            // Device list
            ListView {
                id: list
                anchors.fill: parent
                visible: root.available && !root.blocked && root.enabled
                clip: true
                spacing: 2
                topMargin: 2
                bottomMargin: 2

                model: root.rows

                delegate: Item {
                    id: delegate

                    required property var modelData
                    required property int index

                    width: list.width
                    height: modelData.kind === "header" ? headerItem.implicitHeight : deviceRow.implicitHeight

                    SectionHeader {
                        id: headerItem
                        visible: delegate.modelData.kind === "header"
                        width: delegate.width
                        label: delegate.modelData.kind === "header" ? delegate.modelData.label : ""
                        count: delegate.modelData.kind === "header" ? delegate.modelData.count : 0
                    }

                    BluetoothRow {
                        id: deviceRow
                        visible: delegate.modelData.kind === "device"
                        width: parent.width
                        mockMode: root.mock
                        dev: delegate.modelData.kind === "device" ? delegate.modelData.dev : null
                        expanded: delegate.modelData.kind === "device"
                            && root.expandedAddress === delegate.modelData.dev.address
                        errorText: delegate.modelData.kind === "device"
                            && root.errorAddress === delegate.modelData.dev.address ? root.errorText : ""

                        onToggleExpanded: {
                            root.expandedAddress = root.expandedAddress === delegate.modelData.dev.address
                                ? "" : delegate.modelData.dev.address;
                            if (root.expandedAddress.length > 0)
                                list.positionViewAtIndex(delegate.index, ListView.Contain);
                        }
                        onPairRequested: root.pair(delegate.modelData.dev)
                        onCancelPairRequested: root.cancelPair(delegate.modelData.dev)
                        onConnectRequested: root.connect(delegate.modelData.dev)
                        onDisconnectRequested: root.disconnect(delegate.modelData.dev)
                        onForgetRequested: root.forget(delegate.modelData.dev)
                    }
                }

                // Empty state while powered and scanning
                EmptyState {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    glyph: Theme.glyphs.btSearching
                    title: "NO DEVICES FOUND"
                    hint: "PUT YOUR DEVICE IN PAIRING MODE"
                }
            }
        }

        // Failure feedback, same slot the network tab uses for its portal hint.
        StyledText {
            Layout.fillWidth: true
            visible: root.errorText.length > 0
            text: root.errorText
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
            color: Theme.colors.error
        }

        // ---------------- adapter footer ----------------
        RowLayout {
            Layout.fillWidth: true
            visible: root.enabled && !root.blocked
            spacing: 8

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: "VISIBLE AS"
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            Item {
                id: aliasSlot

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.aliasEditing ? 160 : aliasText.implicitWidth
                implicitHeight: 22

                StyledText {
                    id: aliasText
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.aliasEditing
                    text: root.alias.length > 0 ? root.alias : "—"
                    font.pixelSize: Theme.font.size.xs
                    color: aliasMa.containsMouse ? Theme.colors.primary : Theme.colors.fgLayer0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Theme.colors.outline
                    }

                    MouseArea {
                        id: aliasMa
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.beginAliasEdit()
                    }
                }

                Rectangle {
                    visible: root.aliasEditing
                    anchors.verticalCenter: parent.verticalCenter
                    width: 160
                    height: 22
                    radius: 0
                    color: Theme.colors.layer1
                    border.width: Theme.frame.line
                    border.color: Theme.colors.primary

                    TextInput {
                        id: aliasField
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: Theme.colors.fgLayer0
                        font.family: Theme.font.main
                        font.pixelSize: Theme.font.size.xs
                        selectByMouse: true
                        text: root.aliasDraft

                        onTextEdited: root.aliasDraft = text
                        onAccepted: root.commitAlias()

                        Keys.onEscapePressed: {
                            root.aliasEditing = false;
                            event.accepted = true;
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: discLabel.implicitWidth + 20
                implicitHeight: 22
                radius: 0
                color: root.discoverable ? Theme.colors.primary
                    : discMa.containsMouse ? Theme.colors.stateHover : "transparent"
                border.width: Theme.frame.line
                border.color: root.discoverable ? Theme.colors.primary : Theme.colors.outlineStrong

                StyledText {
                    id: discLabel
                    anchors.centerIn: parent
                    text: "DISCOVERABLE"
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.tracking
                    color: root.discoverable ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
                }

                MouseArea {
                    id: discMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleDiscoverable()
                }
            }
        }
    }
}
