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
    required property bool expanded
    property string errorText: ""

    signal toggleExpanded()
    signal connectRequested()
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
    readonly property bool wep: net.security === WifiSecurityType.StaticWep || net.security === WifiSecurityType.DynamicWep
    readonly property bool pskCapable: [
        WifiSecurityType.WpaPsk,
        WifiSecurityType.Wpa2Psk,
        WifiSecurityType.Sae,
        WifiSecurityType.StaticWep
    ].includes(net.security)
    readonly property bool enterprise: [
        WifiSecurityType.WpaEap,
        WifiSecurityType.Wpa2Eap,
        WifiSecurityType.Leap
    ].includes(net.security)
    readonly property bool secure: net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Owe
    readonly property bool connecting: net.stateChanging || net.state === ConnectionState.Connecting

    readonly property string signalGlyph: [
        Theme.glyphs.wifi0,
        Theme.glyphs.wifi1,
        Theme.glyphs.wifi2,
        Theme.glyphs.wifi3,
        Theme.glyphs.wifi4
    ][Net.signalLevel(net.signalStrength)]

    readonly property string subtitle: {
        if (root.connecting)
            return "CONNECTING...";
        const sec = root.securityLabel(root.net.security);
        if (root.net.connected)
            return "CONNECTED · " + sec;
        if (root.net.known)
            return "SAVED · " + sec;
        return sec;
    }

    // A passphrase is being asked for right now.
    readonly property bool asksPsk: root.expanded && !net.known && pskCapable
    readonly property bool acceptable: Net.isValidPsk(root.wep, pskField.text)

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
                color: headMa.containsMouse && !rowHoverElsewhere ? Theme.colors.stateHover : "transparent"

                Ripple {
                    id: ripple
                    anchors.fill: parent
                    color: ColorUtils.transparentize(Theme.colors.fgLayer1, 0.78)
                }
            }

            // The forget glyph sits inside the row; hover on it should not light
            // the whole row like a normal hover.
            readonly property bool rowHoverElsewhere: headMa.containsMouse && !forgetMa.containsMouse

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.signalGlyph
                    font.family: Theme.font.icon
                    font.pixelSize: 20
                    color: root.net.connected ? Theme.colors.primary : Theme.colors.subtext
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 1

                    StyledText {
                        Layout.fillWidth: true
                        text: root.net.name
                        font.pixelSize: Theme.font.size.md
                        color: root.net.connected ? Theme.colors.primary : Theme.colors.fgLayer0
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
                    visible: !root.connecting && root.net.known && !root.net.connected && headMa.containsMouse
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

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.connecting
                    text: Theme.glyphs.wifiBusy
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: Theme.colors.primary

                    RotationAnimator on rotation {
                        running: root.connecting
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: !root.connecting && root.secure
                    text: Theme.glyphs.wifiSecure
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: root.net.connected ? Theme.colors.primary : Theme.colors.subtext
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
                    if (root.net.connected || root.enterprise || (root.secure && !root.net.known && root.pskCapable))
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
            visible: root.expanded
            spacing: 8
            topPadding: 2
            bottomPadding: 10
            leftPadding: 44
            rightPadding: 12

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

                        property bool revealed: false

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
                                root.pskSubmitted(text);
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
                    onClicked: root.pskSubmitted(pskField.text)
                }
            }

            // Enterprise networks cannot be set up with just a passphrase.
            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: root.expanded && root.enterprise && !root.net.known
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
                visible: root.expanded && root.net.connected

                MicroButton {
                    label: "DISCONNECT"
                    onClicked: root.disconnectRequested()
                }

                MicroButton {
                    label: "FORGET"
                    onClicked: root.forgetRequested()
                }
            }

            // Address of the live connection
            StyledText {
                width: parent.width - parent.leftPadding - parent.rightPadding
                visible: root.net.connected && root.net.address.length > 0
                text: "IP " + root.net.address
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }
        }
    }
}
