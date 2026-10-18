// One wifi network. Clicking a disconnected network connects it; a secured
// network with no saved profile expands in place for the passphrase (the
// plasma-nm applet pattern -- Connect stays disabled until the field validates
// for that security type). A connected row expands to Disconnect / Forget, and
// a saved row reveals Forget on hover so the fast path stays one click.
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.modules
import qs.modules.widgets
import "network_list.js" as Net

Item {
    id: root

    required property var net

    // NM deletes a network object when its access point disappears, and the view
    // can hold that dead wrapper for a frame. Reading a property off it throws
    // ("Value is null and could not be converted to an object"), and no null
    // check or `?.` can see it: the JS value is not null, the QObject behind it
    // is gone. So every read goes through `n()`, which probes and falls back.
    function n() {
        try {
            if (root.net === null || root.net === undefined)
                return root.emptyNet;
            void root.net.name; // touching a property is the aliveness test
            return root.net;
        } catch (e) {
            return root.emptyNet;
        }
    }

    readonly property var emptyNet: ({
        name: "",
        signalStrength: 0,
        security: WifiSecurityType.Unknown,
        connected: false,
        known: false,
        state: ConnectionState.Disconnected,
        stateChanging: false
    })

    visible: root.net !== null && root.net !== undefined
    required property bool expanded
    // The passphrase text lives in the section, not the delegate: a view reset
    // can never lose what has been typed.
    required property string draft
    // The IP lives on the WifiDevice, not on the network object.
    property string deviceAddress: ""
    property string errorText: ""

    signal toggleExpanded()
    signal connectRequested()
    signal draftEdited(string text)
    signal pskSubmitted(string psk)
    signal disconnectRequested()
    signal forgetRequested()
    signal failed(int reason)

    // NM reports passphrase problems as a failure on the network object.
    Connections {
        target: root.net

        function onConnectionFailed(reason) {
            root.failed(reason);
        }
    }

    // Simple (passphrase) security vs enterprise, which needs a full editor.
    readonly property bool wep: n().security === WifiSecurityType.StaticWep || n().security === WifiSecurityType.DynamicWep
    readonly property bool pskCapable: [
        WifiSecurityType.WpaPsk,
        WifiSecurityType.Wpa2Psk,
        WifiSecurityType.Sae,
        WifiSecurityType.StaticWep
    ].includes(n().security)
    readonly property bool enterprise: [
        WifiSecurityType.WpaEap,
        WifiSecurityType.Wpa2Eap,
        WifiSecurityType.Leap
    ].includes(n().security)
    readonly property bool secure: n().security !== WifiSecurityType.Open && n().security !== WifiSecurityType.Owe
    readonly property bool connecting: n().stateChanging || n().state === ConnectionState.Connecting

    // State first; the security label only where it adds information (the lock
    // glyph already marks a secured network).
    readonly property string subtitle: {
        if (root.connecting)
            return "CONNECTING…";
        if (n().connected)
            return "CONNECTED";
        if (n().known)
            return "SAVED";
        return root.securityLabel(n().security);
    }

    // A passphrase is being asked for right now.
    readonly property bool asksPsk: root.expanded && !n().known && pskCapable
    readonly property bool acceptable: Net.isValidPsk(root.wep, root.draft)

    // Focus is granted asynchronously by the compositor (same delayed grab the
    // launcher uses for its search field).
    Timer {
        id: focusTimer
        interval: 120
        onTriggered: if (root.asksPsk) pskField.forceActiveFocus()
    }

    onAsksPskChanged: if (root.asksPsk) focusTimer.restart()
    Component.onCompleted: if (root.asksPsk) focusTimer.restart()

    function securityLabel(type) {
        switch (type) {
        case WifiSecurityType.Open:
            return "OPEN";
        case WifiSecurityType.Owe:
            return "OWE";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.Wpa3SuiteB192:
            return "WPA3-192";
        case WifiSecurityType.WpaEap:
            return "WPA-EAP";
        case WifiSecurityType.Wpa2Eap:
            return "WPA2-EAP";
        case WifiSecurityType.Leap:
            return "LEAP";
        default:
            return "UNKNOWN";
        }
    }

    implicitWidth: parent?.width ?? 640
    implicitHeight: col.implicitHeight

    component MicroButton: Rectangle {
        id: btn

        property string label
        property bool accent: false

        signal clicked()

        implicitWidth: btnLabel.implicitWidth + 24
        implicitHeight: 26
        radius: 0
        color: btnMa.containsMouse ? (btn.accent ? Theme.colors.primary : Theme.colors.stateHover) : "transparent"
        border.width: Theme.frame.line
        border.color: btn.accent ? Theme.colors.primary : Theme.colors.outlineStrong

        StyledText {
            id: btnLabel
            anchors.centerIn: parent
            text: btn.label
            font.pixelSize: Theme.frame.labelSize
            font.letterSpacing: Theme.frame.tracking
            color: btnMa.containsMouse && btn.accent ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
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
                color: headMa.containsMouse && !forgetMa.containsMouse ? Theme.colors.stateHover : "transparent"

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

                SignalBars {
                    Layout.alignment: Qt.AlignVCenter
                    level: n().signalStrength
                    color: n().connected ? Theme.colors.primary : Theme.colors.subtext
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: n().name
                        font.pixelSize: Theme.font.size.md
                        color: n().connected ? Theme.colors.primary : Theme.colors.fgLayer0
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

                // Saved + idle: reveal Forget on hover (the row click connects).
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: !root.connecting && n().known && !n().connected && headMa.containsMouse
                    text: Theme.glyphs.wifiForget
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: forgetMa.containsMouse ? Theme.colors.error : Theme.colors.subtext

                    MouseArea {
                        id: forgetMa
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.forgetRequested()
                    }
                }

                Spinner {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.connecting
                    running: root.connecting
                    size: 16
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: !root.connecting && root.secure
                    text: Theme.glyphs.wifiSecure
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: n().connected ? Theme.colors.primary : Theme.colors.subtext
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
                    if (n().connected || root.enterprise || (root.secure && !n().known && root.pskCapable))
                        root.toggleExpanded();
                    else
                        root.connectRequested();
                }
            }
        }

        // ---------------- expanded body (height + fade animated) ----------------
        Column {
            id: body

            width: parent.width
            height: root.expanded ? implicitHeight : 0
            clip: true
            opacity: root.expanded ? 1 : 0
            // Collapsed children still exist while animating; keep them inert.
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

            // Passphrase for a new secured network
            Row {
                width: parent.width - parent.leftPadding - parent.rightPadding
                spacing: 8
                visible: root.asksPsk

                Rectangle {
                    id: pskBox

                    width: parent.width - reveal.width - 8 - connect.width - 8
                    height: 34
                    radius: 0
                    color: Theme.colors.layer1
                    border.width: Theme.frame.line
                    border.color: pskField.activeFocus ? Theme.colors.primary : Theme.colors.outline

                    TextInput {
                        id: pskField

                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        focus: root.asksPsk
                        clip: true
                        color: Theme.colors.fgLayer0
                        font.family: Theme.font.main
                        font.pixelSize: Theme.font.size.sm
                        echoMode: revealed ? TextInput.Normal : TextInput.Password
                        selectByMouse: true
                        text: root.draft

                        property bool revealed: false

                        onTextEdited: root.draftEdited(text)

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "PASSWORD"
                            font.pixelSize: Theme.frame.labelSize
                            font.letterSpacing: Theme.frame.tracking
                            color: Theme.colors.subtext
                            opacity: 0.6
                            visible: !pskField.text
                        }

                        onAccepted: {
                            if (root.acceptable)
                                root.pskSubmitted(root.draft);
                        }
                    }
                }

                StyledText {
                    id: reveal

                    anchors.verticalCenter: parent.verticalCenter
                    text: pskField.revealed ? Theme.glyphs.revealOff : Theme.glyphs.revealOn
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: revealMa.containsMouse ? Theme.colors.primary : Theme.colors.subtext

                    MouseArea {
                        id: revealMa
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pskField.revealed = !pskField.revealed
                    }
                }

                MicroButton {
                    id: connect

                    anchors.verticalCenter: parent.verticalCenter
                    label: "CONNECT"
                    accent: true
                    enabled: root.acceptable
                    opacity: root.acceptable ? 1 : 0.4
                    onClicked: root.pskSubmitted(root.draft)

                    Behavior on opacity {
                        ColorAnimation {
                            duration: Theme.animation.valueDuration
                        }
                    }
                }
            }

            // Enterprise networks cannot be set up with just a passphrase.
            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: root.expanded && root.enterprise && !n().known
                text: "ENTERPRISE — NEEDS A SAVED PROFILE"
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.warning
            }

            // Failure feedback (e.g. wrong passphrase)
            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: root.errorText.length > 0
                text: root.errorText
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.error
            }

            // Actions for the live connection
            Row {
                width: parent.width - parent.leftPadding - parent.rightPadding
                spacing: 8
                visible: root.expanded && n().connected

                MicroButton {
                    label: "DISCONNECT"
                    onClicked: root.disconnectRequested()
                }

                MicroButton {
                    label: "FORGET"
                    onClicked: root.forgetRequested()
                }
            }

            // Address of the live connection (from the device, not the network)
            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: n().connected && root.deviceAddress.length > 0
                text: "IP " + root.deviceAddress
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }
        }
    }
}
