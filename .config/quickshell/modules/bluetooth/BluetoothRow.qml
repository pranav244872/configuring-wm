// One Bluetooth device. Clicking a paired-but-idle device connects it (fast
// path); a connected device or a newly discovered one expands in place -- a
// discovered device has to be looked at before it is paired, and a connected one
// expands to Disconnect / Forget. Same interaction grammar as NetworkRow.
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.modules
import qs.modules.widgets
import "bluetooth_model.js" as Bt

Item {
    id: root

    required property var dev
    required property bool expanded
    // Bench rows are plain objects: never call methods on them.
    property bool mockMode: false
    property string errorText: ""

    signal toggleExpanded()
    signal connectRequested()
    signal disconnectRequested()
    signal pairRequested()
    signal cancelPairRequested()
    signal forgetRequested()

    // A device object can be destroyed by BlueZ between a model update and the
    // next paint. Touching a property is the aliveness test; every read goes
    // through d() so a dead wrapper cannot throw (the network row's n()).
    readonly property var emptyDev: ({
        name: "",
        deviceName: "",
        address: "",
        icon: "",
        state: BluetoothDeviceState.Disconnected,
        connected: false,
        paired: false,
        pairing: false,
        trusted: false,
        batteryAvailable: false,
        battery: 0
    })

    function d() {
        try {
            if (root.dev === null || root.dev === undefined)
                return root.emptyDev;
            void root.dev.name;
            return root.dev;
        } catch (e) {
            return root.emptyDev;
        }
    }

    readonly property string name: Bt.label(d())
    readonly property string typeName: Bt.typeLabel(d().icon)
    readonly property string battery: Bt.batteryText(d())
    readonly property bool connecting: d().state === BluetoothDeviceState.Connecting
    readonly property bool disconnecting: d().state === BluetoothDeviceState.Disconnecting
    readonly property bool busy: d().pairing || root.connecting || root.disconnecting
    readonly property bool lowBattery: d().batteryAvailable && d().battery < 0.2

    // State first; battery is drawn separately so it stays scannable.
    readonly property string subtitle: {
        if (d().pairing)
            return "PAIRING…";
        if (root.connecting)
            return "CONNECTING…";
        if (root.disconnecting)
            return "DISCONNECTING…";
        if (d().connected)
            return "CONNECTED";
        if (d().paired)
            return "PAIRED";
        return "NOT PAIRED";
    }

    property bool confirmingForget: false

    Timer {
        id: confirmReset
        interval: 3000
        onTriggered: root.confirmingForget = false
    }

    onExpandedChanged: if (!root.expanded) root.confirmingForget = false

    implicitWidth: parent?.width ?? 640
    implicitHeight: col.implicitHeight

    component MicroButton: Rectangle {
        id: btn

        property string label
        property bool accent: false
        property bool danger: false

        signal clicked()

        implicitWidth: btnLabel.implicitWidth + 24
        implicitHeight: 26
        radius: 0
        color: btnMa.containsMouse ? (btn.accent ? Theme.colors.primary
            : btn.danger ? Theme.colors.error : Theme.colors.stateHover) : "transparent"
        border.width: Theme.frame.line
        border.color: btn.accent ? Theme.colors.primary
            : btn.danger ? Theme.colors.error : Theme.colors.outlineStrong

        StyledText {
            id: btnLabel
            anchors.centerIn: parent
            text: btn.label
            font.pixelSize: Theme.frame.labelSize
            font.letterSpacing: Theme.frame.tracking
            color: btnMa.containsMouse && (btn.accent || btn.danger) ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Column {
        id: col
        width: parent.width

        // ---------------- header row (click target) ----------------
        Item {
            id: header

            width: parent.width
            height: 46

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                color: headMa.containsMouse ? Theme.colors.stateHover : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animation.valueDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.animation.curveOut
                    }
                }

                Ripple {
                    id: ripple
                    anchors.fill: parent
                    color: ColorUtils.transparentize(Theme.colors.fgLayer1, 0.78)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Bt.glyph(d().icon)
                    font.family: Theme.font.icon
                    font.pixelSize: 20
                    color: d().connected ? Theme.colors.primary : Theme.colors.subtext
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: root.name
                        font.pixelSize: Theme.font.size.md
                        color: d().connected ? Theme.colors.primary : Theme.colors.fgLayer0
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.subtitle
                        font.pixelSize: Theme.font.size.xs
                        font.letterSpacing: Theme.frame.tracking
                        color: Theme.colors.subtext
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.battery.length > 0
                    text: root.battery
                    font.pixelSize: Theme.font.size.xs
                    font.letterSpacing: Theme.frame.tracking
                    color: root.lowBattery ? Theme.colors.error
                        : d().connected ? Theme.colors.primary : Theme.colors.subtext
                }

                Spinner {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.busy
                    running: root.busy
                    size: 16
                }
            }

            MouseArea {
                id: headMa

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton

                onPressed: (event) => ripple.press(headMa.mouseX, headMa.mouseY)
                onReleased: ripple.release()
                onCanceled: ripple.release()

                onClicked: {
                    if (root.busy)
                        return;
                    if (d().connected || !d().paired)
                        root.toggleExpanded();
                    else
                        root.connectRequested();
                }
            }
        }

        // ---------------- expanded body ----------------
        Column {
            id: body

            width: parent.width
            height: root.expanded ? implicitHeight : 0
            clip: true
            opacity: root.expanded ? 1 : 0
            enabled: root.expanded
            spacing: 8
            topPadding: 2
            bottomPadding: 10
            leftPadding: 44
            rightPadding: 12

            Behavior on height {
                NumberAnimation {
                    duration: root.expanded ? Theme.animation.enterDuration : Theme.animation.exitDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.expanded ? Theme.animation.curveOut : Theme.animation.curveIn
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.expanded ? Theme.animation.enterDuration : Theme.animation.exitDuration
                }
            }

            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                text: "ADDRESS  " + (d().address || "—")
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                text: "TYPE  " + root.typeName
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: root.lowBattery ? Theme.colors.error : Theme.colors.subtext
            }

            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: root.errorText.length > 0
                text: root.errorText
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.error
            }

            Row {
                width: parent.width - parent.leftPadding - parent.rightPadding
                spacing: 8

                MicroButton {
                    visible: d().pairing
                    label: "CANCEL"
                    danger: true
                    onClicked: root.cancelPairRequested()
                }

                MicroButton {
                    visible: !d().pairing && !d().paired
                    label: "PAIR"
                    accent: true
                    onClicked: root.pairRequested()
                }

                MicroButton {
                    visible: !d().pairing && d().paired && !d().connected
                    label: "CONNECT"
                    accent: true
                    enabled: !root.busy
                    opacity: root.busy ? 0.4 : 1
                    onClicked: root.connectRequested()
                }

                MicroButton {
                    visible: !d().pairing && d().connected
                    label: "DISCONNECT"
                    enabled: !root.busy
                    opacity: root.busy ? 0.4 : 1
                    onClicked: root.disconnectRequested()
                }

                MicroButton {
                    visible: !d().pairing
                    label: root.confirmingForget ? "CONFIRM" : "FORGET"
                    danger: root.confirmingForget
                    onClicked: {
                        if (root.confirmingForget) {
                            root.confirmingForget = false;
                            root.forgetRequested();
                        } else {
                            root.confirmingForget = true;
                            confirmReset.restart();
                        }
                    }
                }
            }
        }
    }
}
