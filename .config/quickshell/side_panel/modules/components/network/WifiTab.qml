import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Io
import "../../../../qs/services"

Item {
    id: rootWifi
    property bool isActiveTab: false
    property bool wifiEnabled: false
    property bool isBlocked: false
    property string expandedSsid: ""
    property bool isScanning: false
    property bool isBusy: forgetWifiProc.running || rfkillUnblockProc.running
    property bool showSaved: false
    property bool isInitialized: false  // true after first power check completes

    ListModel { id: wifiModel }
    ListModel { id: savedWifiModel }

    Process {
        id: rfkillCheckProc
        command: ["rfkill", "list", "wlan"]
        stdout: StdioCollector {
            onStreamFinished: {
                isBlocked = text.includes("Soft blocked: yes") || text.includes("Hard blocked: yes")
                console.log("[Wi-Fi] rfkill check - blocked:", isBlocked)
                if (!isBlocked && wifiEnabled && isActiveTab) {
                    wifiScanProc.running = true
                    savedWifiNetworksProc.running = true
                }
            }
        }
    }

    Process {
        id: rfkillUnblockProc
        command: ["rfkill", "unblock", "wlan"]
        onExited: {
            console.log("[Wi-Fi] rfkill unblock completed")
            rfkillCheckProc.running = true
            wifiPowerProc.running = true
        }
    }

    Process {
        id: wifiPowerProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiEnabled = text.trim() === "enabled"
                console.log("[Wi-Fi] Power state:", wifiEnabled ? "ON" : "OFF")
                // ONLY trigger scan after we know power state — fixes 'shows as OFF' on first open
                if (wifiEnabled && !isBlocked) {
                    isScanning = true
                    wifiScanProc.running = true
                    savedWifiNetworksProc.running = true
                }
                isInitialized = true
            }
        }
    }

    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SSID,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear()
                const lines = text.trim().split("\n")
                const seen = new Set()
                let activeSsid = ""

                // First pass: find active network and mark as seen
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    const parts = lines[i].split(":")
                    if (parts.length >= 3 && parts[0] === "*" && parts[2]) {
                        activeSsid = parts[2]
                        seen.add(activeSsid)
                        break
                    }
                }
                console.log("[Wi-Fi] Currently connected to:", activeSsid || "none")

                // Second pass: add networks
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    const parts = lines[i].split(":")
                    if (parts.length >= 4) {
                        const inUse = parts[0] === "*"
                        const strength = parseInt(parts[1], 10) || 0
                        const ssidName = parts[2]
                        const securityStr = parts.slice(3).join(":").trim()

                        if (!ssidName || ssidName === "--") continue

                        // Always include active network, skip duplicates for others
                        if (inUse || !seen.has(ssidName)) {
                            if (!inUse) seen.add(ssidName)

                            let isNetSaved = false;
                            for (let j = 0; j < savedWifiModel.count; j++) {
                                if (savedWifiModel.get(j).networkName === ssidName) {
                                    isNetSaved = true;
                                    break;
                                }
                            }

                            wifiModel.append({
                                "isActiveNet": inUse,
                                "signalStrength": strength,
                                "networkSsid": ssidName,
                                "isSecureNet": securityStr.length > 0 && securityStr !== "--" && securityStr !== "none",
                                "isSavedNet": isNetSaved
                            })
                        }
                    }
                }
                console.log("[Wi-Fi] Loaded", wifiModel.count, "networks, scan complete")
                isScanning = false
            }
        }
    }

    Process {
        id: savedWifiNetworksProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                savedWifiModel.clear()
                const lines = text.trim().split("\n")
                const seen = new Set()
                for (let i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    const parts = lines[i].split(":")
                    if (parts.length >= 2 && parts[1].includes("wireless")) {
                        const name = parts[0]
                        if (name && !seen.has(name)) {
                            seen.add(name)
                            savedWifiModel.append({ "networkName": name })
                        }
                    }
                }
                console.log("[Wi-Fi] Saved networks:", savedWifiModel.count)
            }
        }
    }

    Process {
        id: wifiConnectProc
        property string targetSsid: ""
        property string targetPassword: ""
        onExited: {
            console.log("[Wi-Fi] Connection process exited for:", targetSsid)
            wifiScanProc.running = true
            savedWifiNetworksProc.running = true
            expandedSsid = ""
        }
    }

    Process {
        id: wifiDisconnectProc
        property string targetSsid: ""
        command: ["nmcli", "device", "disconnect", "wlp0s20f3"]
        onExited: {
            console.log("[Wi-Fi] Disconnected from:", targetSsid)
            targetSsid = ""
            wifiScanProc.running = true
        }
    }

    Process {
        id: forgetWifiProc
        property string targetSsid: ""
        command: ["nmcli", "connection", "delete", targetSsid]
        onExited: {
            console.log("[Wi-Fi] Forgot network:", targetSsid)
            savedWifiNetworksProc.running = true
            wifiScanProc.running = true
        }
    }

    Timer {
        interval: 15000
        running: isActiveTab && !isBusy && NetworkMenuService.showMenu
        repeat: true
        onTriggered: {
            rfkillCheckProc.running = true
            wifiPowerProc.running = true
            if (wifiEnabled && !isBlocked) {
                wifiScanProc.running = true
            }
        }
    }

    onIsActiveTabChanged: {
        if (isActiveTab && NetworkMenuService.showMenu) {
            // Reset init state so loading indicator shows on each open
            isInitialized = false
            isScanning = true
            // Run rfkill check first, then power check — power check triggers scan
            rfkillCheckProc.running = true
            savedWifiNetworksProc.running = true
            wifiPowerProc.running = true
        }
    }

    // ── UI ───────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ── Header row: title + scan + toggle ───────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Wi-Fi Networks"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: Colors.m3.on_surface
            }

            // Scan button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: scanMa.containsMouse ? Qt.rgba(Colors.m3.on_surface.r, Colors.m3.on_surface.g, Colors.m3.on_surface.b, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: isScanning ? Colors.m3.primary : Colors.m3.on_surface_variant
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 1000
                        running: isScanning
                    }
                }
                MouseArea {
                    id: scanMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !isScanning && !isBusy
                    onClicked: {
                        isScanning = true
                        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"])
                        wifiScanProc.running = true
                        savedWifiNetworksProc.running = true
                    }
                }
            }

            // Power toggle
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 26
                radius: 13
                color: wifiEnabled && !isBlocked ? Colors.m3.primary : Colors.m3.surface_container_highest
                border.color: wifiEnabled && !isBlocked ? "transparent" : Colors.m3.outline
                border.width: 1
                Behavior on color { ColorAnimation { duration: 200 } }

                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: wifiEnabled && !isBlocked ? parent.width - width - 4 : 4
                    color: wifiEnabled && !isBlocked ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !isBusy && !isBlocked
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
                        wifiPowerProc.running = true
                    }
                }
            }
        }

        // ── rfkill blocked banner ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 12
            color: Colors.m3.error_container
            visible: isBlocked

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14; anchors.rightMargin: 14
                spacing: 10
                Text {
                    text: "󰤮"
                    font.family: "Material Design Icons"
                    font.pixelSize: 18
                    color: Colors.m3.on_error_container
                }
                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi is blocked by rfkill"
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: Colors.m3.on_error_container
                }
                Rectangle {
                    Layout.preferredWidth: 66
                    Layout.preferredHeight: 26
                    radius: 13
                    color: Colors.m3.error
                    Text {
                        anchors.centerIn: parent
                        text: "Unblock"
                        font.family: "Inter"; font.pixelSize: 12; font.bold: true
                        color: Colors.m3.on_error
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rfkillUnblockProc.running = true
                    }
                }
            }
        }

        // ── Loading indicator (shown before first power check completes) ───────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !isInitialized

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "sync"
                    font.family: "Material Icons Round"
                    font.pixelSize: 32
                    color: Colors.m3.primary
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                        running: !isInitialized
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Checking network state…"
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: Colors.m3.on_surface_variant
                }
            }
        }

        // ── Available networks list ─────────────────────────────────────────
        ListView {
            id: networksList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            visible: isInitialized
            model: isInitialized && wifiEnabled && !isBlocked ? wifiModel : null
            enabled: !isBusy

            delegate: WifiNetworkDelegate {
                ssid: model.networkSsid
                signalStr: model.signalStrength
                isActive: model.isActiveNet
                isSecure: model.isSecureNet
                isSaved: model.isSavedNet
                isExpanded: rootWifi.expandedSsid === model.networkSsid

                onRequestExpand: function(reqSsid) {
                    rootWifi.expandedSsid = rootWifi.expandedSsid === reqSsid ? "" : reqSsid
                }
                onRequestConnect: function(reqSsid, password) {
                    wifiConnectProc.targetSsid = reqSsid
                    wifiConnectProc.targetPassword = password
                    wifiConnectProc.command = password 
                        ? ["nmcli", "device", "wifi", "connect", reqSsid, "password", password] 
                        : ["nmcli", "device", "wifi", "connect", reqSsid]
                    wifiConnectProc.running = true
                }
                onRequestDisconnect: function(reqSsid) {
                    wifiDisconnectProc.targetSsid = reqSsid
                    wifiDisconnectProc.running = true
                }
            }

            // Empty state (Scanning / No networks)
            Text {
                anchors.centerIn: parent
                visible: networksList.count === 0 && wifiEnabled && !isBlocked && !isScanning
                text: "No networks found"
                font.family: "Inter"; font.pixelSize: 14
                color: Colors.m3.outline
            }
        }

        // ── Wi-Fi Disabled / Empty state ──────────────────────────────────────
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: isInitialized && (!wifiEnabled || isBlocked)
            spacing: 16

            Item { Layout.fillHeight: true } // Spacer
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: isBlocked ? "󰤮" : "󰖪"
                font.family: "Material Design Icons"
                font.pixelSize: 48
                color: Colors.m3.on_surface_variant
                opacity: 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: isBlocked ? "Wi-Fi is blocked" : "Wi-Fi is turned off"
                font.family: "Inter"
                font.pixelSize: 16
                font.bold: true
                color: Colors.m3.on_surface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn it on to see available networks"
                font.family: "Inter"
                font.pixelSize: 13
                color: Colors.m3.on_surface_variant
                visible: !isBlocked
            }
            
            Item { Layout.fillHeight: true } // Spacer
        }

        // ── Saved networks (collapsible) ────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: showSaved ? savedCol.implicitHeight + 16 : 40
            radius: 14
            color: Colors.m3.surface_container_high
            clip: true
            visible: savedWifiModel.count > 0 && wifiEnabled && !isBlocked

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Column {
                id: savedCol
                width: parent.width
                spacing: 6

                // Header (always visible, acts as toggle)
                Item {
                    width: parent.width
                    height: 40

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "󰤓"
                            font.family: "Material Design Icons"
                            font.pixelSize: 16
                            color: Colors.m3.on_surface_variant
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Saved Networks (" + savedWifiModel.count + ")"
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: Colors.m3.on_surface
                        }
                        Text {
                            text: showSaved ? "󰅂" : "󰅀"
                            font.family: "Material Design Icons"
                            font.pixelSize: 18
                            color: Colors.m3.on_surface_variant

                            Behavior on text { SequentialAnimation {
                                NumberAnimation { target: parent; property: "opacity"; to: 0; duration: 60 }
                                PropertyAction {}
                                NumberAnimation { target: parent; property: "opacity"; to: 1; duration: 60 }
                            }}
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: showSaved = !showSaved
                    }
                }

                // Saved network items
                Column {
                    width: parent.width - 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    visible: showSaved
                    opacity: showSaved ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Repeater {
                        model: savedWifiModel

                        delegate: SavedWifiDelegate {
                            width: parent.width
                            networkName: model.networkName
                            onRequestForget: function(ssid) {
                                forgetWifiProc.targetSsid = ssid
                                forgetWifiProc.running = true
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Busy overlay ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.m3.surface_container.r, Colors.m3.surface_container.g, Colors.m3.surface_container.b, 0.5)
        visible: isBusy
        radius: 14
        z: 99
        MouseArea { anchors.fill: parent; hoverEnabled: true }

        Column {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰑐"
                font.family: "Material Design Icons"
                font.pixelSize: 28
                color: Colors.m3.primary
                RotationAnimation on rotation {
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 1000
                    running: true
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Working…"
                font.family: "Inter"; font.pixelSize: 13
                color: Colors.m3.on_surface_variant
            }
        }
    }
}
