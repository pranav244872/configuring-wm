// Network status: the signal meter alone at rest (the battery's icon-only
// treatment), with the details in a tooltip below the bar on hover -- waybar's
// tooltip pattern, via a PopupWindow anchored to this item.
//
// Native Quickshell.Networking -- no nmcli subprocess and no polling:
// signalStrength/connected are bindable properties.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.modules
import qs.modules.widgets

Item {
    id: root

    // Bench hooks: previews drive the item without a live link (same idea as
    // NetworkSection.mock) and pin the tooltip open (a bench has no pointer).
    property bool mock: false
    property string mockSsid: ""
    property real mockLevel: 0
    property string mockState: "connected" // connected | portal | disconnected | off
    property bool pinTooltip: false

    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    // Guard against dead wrappers: NM deletes a network object when its AP
    // disappears, which can leave a null in a freshly read list.
    readonly property var ap: dev?.networks?.values?.find(n => n && n.connected) ?? null

    readonly property bool radioOn: Networking.wifiEnabled
    // Portal/Limited come from NM's connectivity check; if checking is off the
    // state reads Unknown and we simply stay in the quiet "connected" look.
    readonly property bool restricted: Networking.connectivity === NetworkConnectivity.Portal
        || Networking.connectivity === NetworkConnectivity.Limited

    readonly property string state: root.mock ? root.mockState
        : (!root.radioOn ? "off"
            : (root.ap ? (root.restricted ? "portal" : "connected") : "disconnected"))
    readonly property string ssid: root.mock ? root.mockSsid : (root.ap?.name ?? "")
    readonly property real level: root.mock ? root.mockLevel : (root.ap?.signalStrength ?? 0)

    readonly property bool online: root.state === "connected" || root.state === "portal"

    // The meter is the item; the down states are glyphs, like the dashboard's
    // rows (bars for strength, an icon for "nothing").
    readonly property color fgColor: {
        if (root.state === "portal")
            return Theme.colors.warning;
        if (root.online)
            return Theme.colors.fgLayer1;
        if (root.state === "off")
            return ColorUtils.transparentize(Theme.colors.fgLayer1, 0.45);
        return Theme.colors.subtext;
    }

    // ---------------------------------------------------------------- tooltip
    // Data verbatim, labels uppercase: an SSID is case-sensitive, a state word
    // is ours.
    readonly property string tipTitle: root.online ? root.ssid : (root.state === "off" ? "WI-FI OFF" : "OFFLINE")
    readonly property color tipTitleColor: root.state === "portal" ? Theme.colors.warning : Theme.colors.fgLayer0
    readonly property string tipNote: root.state === "portal" ? "PORTAL — SIGN IN TO GET ONLINE" : ""

    readonly property string securityText: {
        if (!root.online)
            return "";
        switch (root.ap?.security) {
        case WifiSecurityType.Open:
            return "OPEN";
        case WifiSecurityType.StaticWep:
        case WifiSecurityType.DynamicWep:
            return "WEP";
        case WifiSecurityType.WpaPsk:
            return "WPA";
        case WifiSecurityType.Wpa2Psk:
            return "WPA2";
        case WifiSecurityType.Wpa3SuiteB192:
        case WifiSecurityType.Sae:
            return "WPA3";
        case WifiSecurityType.WpaEap:
        case WifiSecurityType.Wpa2Eap:
            return "802.1X";
        case WifiSecurityType.Owe:
            return "OWE";
        default:
            return "";
        }
    }

    readonly property string tipDetail: {
        if (!root.online)
            return root.state === "off" ? "RADIO DISABLED" : "NO NETWORK CONNECTED";
        const parts = [Math.round(root.level * 100) + "%"];
        if (root.securityText.length > 0)
            parts.push(root.securityText);
        if (root.ipAddress.length > 0)
            parts.push(root.ipAddress);
        return parts.join(" · ");
    }

    // The IP is the one bit of the tooltip the toolkit doesn't expose (device
    // address is the MAC), so it is looked up once per hover -- not polled.
    property string ipAddress: ""

    Process {
        id: ipProc
        command: ["ip", "-4", "-o", "addr", "show", "dev", root.dev?.name ?? ""]

        stdout: SplitParser {
            onRead: line => {
                const m = /inet ([0-9.]+)/.exec(line);
                if (m)
                    root.ipAddress = m[1];
            }
        }
    }

    property bool tooltipOpen: false
    readonly property bool tooltipVisible: root.pinTooltip || root.tooltipOpen

    // Read the IP into place *before* the tooltip maps (the hover path calls
    // this as the dwell starts, so the popup opens at its final width) and
    // again if the connection only appears while it is already visible -- at
    // startup the device can be unresolved when the popup is pinned open.
    function refreshIp() {
        root.ipAddress = root.mock ? root.mockIp : "";
        if (!root.mock && root.online && (root.dev?.name ?? "").length > 0)
            ipProc.running = true;
    }

    onTooltipVisibleChanged: if (!root.tooltipVisible) root.tooltipOpen = false
    onDevChanged: if (root.tooltipVisible) root.refreshIp()
    onOnlineChanged: if (root.tooltipVisible) root.refreshIp()

    // 300ms dwell: the same vocabulary as the hot zones. Sweeping the pointer
    // across the bar must not flash tooltips.
    Timer {
        id: hoverDwell
        interval: 300
        onTriggered: root.tooltipOpen = true
    }

    // 4px of state-layer bleed each side, like the caffeine button's 22px box.
    implicitWidth: meter.implicitWidth + 8
    implicitHeight: meter.implicitHeight

    Rectangle {
        anchors.fill: parent
        color: ma.containsMouse ? Theme.colors.stateHover : "transparent"
    }

    // Fixed meter slot, so the down-state glyph and the bars share a width.
    Item {
        id: meter
        anchors.centerIn: parent
        implicitWidth: 17
        implicitHeight: 16

        SignalBars {
            anchors.centerIn: parent
            visible: root.online
            level: root.level
            maxHeight: 12
            color: root.fgColor
        }

        Glyph {
            anchors.centerIn: parent
            visible: !root.online
            text: root.state === "off" ? Theme.glyphs.wifiOff : Theme.glyphs.wifiFind
            color: root.fgColor
            font.pixelSize: 16
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.mock
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "dashboard", "toggle"])

        onContainsMouseChanged: {
            if (containsMouse) {
                // Fetch while the dwell is running: the popup then opens at its
                // final width instead of growing under the pointer.
                root.refreshIp();
                hoverDwell.restart();
            } else {
                hoverDwell.stop();
                root.tooltipOpen = false;
            }
        }
    }

    Loader {
        active: root.tooltipVisible

        sourceComponent: PopupWindow {
            id: tip

            visible: true
            color: "transparent"
            // Click-through: the tooltip must never eat a click.
            mask: Region {
                item: null
            }

            // Centred under the item and clear of the bar: the anchor point is
            // the *bar's* bottom edge (the item sits mid-bar, so its own bottom
            // would put the box inside the bar). Window + rect (not `item`) so
            // the position is ours, matching the toolkit's example.
            anchor {
                window: root.QsWindow.window

                rect.x: root.mapToItem(null, 0, 0).x + (root.width - tip.implicitWidth) / 2
                rect.y: root.QsWindow.window.height + 6
            }

            implicitWidth: tipContent.implicitWidth
            implicitHeight: tipContent.implicitHeight

            // Small live changes (signal digits, the IP) resize the box while
            // it is open; re-anchor so it stays centred under the item.
            onImplicitWidthChanged: Qt.callLater(tip.anchor.updateAnchor)

            NetworkTooltip {
                id: tipContent
                title: root.tipTitle
                detail: root.tipDetail
                note: root.tipNote
                titleColor: root.tipTitleColor
            }

            // The Loader rebuilds this on every open, so this is "on open".
            Component.onCompleted: root.refreshIp()
        }
    }
}
