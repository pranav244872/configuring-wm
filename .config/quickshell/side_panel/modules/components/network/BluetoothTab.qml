import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../../../../qs/services"
import "BluetoothDeviceDelegate.qml"

Item {
    id: rootBt
    property bool isActiveTab: false
    property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    property bool isBlocked: false
    readonly property bool isScanning: Bluetooth.defaultAdapter?.discovering ?? false
    property bool isBusy: btConnectProc.running || btDisconnectProc.running || rfkillUnblockProc.running

    Process {
        id: rfkillCheckProc
        command: ["rfkill", "list", "bluetooth"]
        stdout: StdioCollector {
            onStreamFinished: {
                isBlocked = text.includes("Soft blocked: yes") || text.includes("Hard blocked: yes")
                console.log("[Bluetooth] rfkill check - blocked:", isBlocked)
            }
        }
    }

    Process {
        id: rfkillUnblockProc
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: {
            console.log("[Bluetooth] rfkill unblock completed")
            rfkillCheckProc.running = true
        }
    }

    Process {
        id: btConnectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "connect", targetAddress]
    }

    Process {
        id: btDisconnectProc
        property string targetAddress: ""
        command: ["bluetoothctl", "disconnect", targetAddress]
        onExited: {
            console.log("[Bluetooth] Disconnected from:", targetAddress)
        }
    }

    onIsActiveTabChanged: {
        rfkillCheckProc.running = true
        if (isActiveTab && Bluetooth.defaultAdapter && btEnabled && !isBlocked) {
            Bluetooth.defaultAdapter.discovering = true
        } else if (!isActiveTab && Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discovering = false
        }
    }

    Timer {
        interval: 10000
        running: isActiveTab && isScanning
        onTriggered: {
            if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.discovering = false
                console.log("[Bluetooth] Auto-stopped discovery")
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: "Bluetooth Devices"
                font.family: "Inter"
                font.pixelSize: 16
                font.bold: true
                color: Colors.m3.on_surface
            }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: isScanning ? Colors.m3.primary : Colors.m3.on_surface_variant
                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 2000
                        running: isScanning
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: btEnabled && !isBlocked
                    onClicked: {
                        if (Bluetooth.defaultAdapter) {
                            console.log("[Bluetooth] Toggle scan:", !isScanning)
                            Bluetooth.defaultAdapter.discovering = !isScanning
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 28
                radius: 14
                color: btEnabled && !isBlocked ? Colors.m3.primary : Colors.m3.surface_container_highest
                border.color: btEnabled && !isBlocked ? "transparent" : Colors.m3.outline
                border.width: 1

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: btEnabled && !isBlocked ? parent.width - width - 4 : 4
                    color: btEnabled && !isBlocked ? Colors.m3.on_primary : Colors.m3.on_surface_variant
                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: !isBusy && !isBlocked
                    onClicked: {
                        if (Bluetooth.defaultAdapter) {
                            console.log("[Bluetooth] Toggle power:", !btEnabled)
                            Bluetooth.defaultAdapter.enabled = !btEnabled
                            if (!btEnabled) Qt.callLater(function() {
                                Bluetooth.defaultAdapter.discovering = true
                            })
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 12
            color: Colors.m3.error_container
            visible: isBlocked

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                Text {
                    text: "󰂲"
                    font.family: "Material Design Icons"
                    font.pixelSize: 20
                    color: Colors.m3.on_error_container
                }
                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth is blocked by rfkill"
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: Colors.m3.on_error_container
                }
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 28
                    radius: 14
                    color: Colors.m3.error
                    Text {
                        anchors.centerIn: parent
                        text: "Unblock"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.m3.on_error
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("[Bluetooth] Unblocking rfkill")
                            rfkillUnblockProc.running = true
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: btListView
                anchors.fill: parent
                clip: true
                spacing: 8
                enabled: !isBusy && !isBlocked

                model: btEnabled && !isBlocked ? (function() {
                    try {
                        const devs = Bluetooth.devices.values.slice()
                        devs.sort(function(a, b) {
                            if (a.connected !== b.connected) return a.connected ? -1 : 1
                            if (a.paired !== b.paired) return a.paired ? -1 : 1
                            return (a.name || "").localeCompare(b.name || "")
                        })
                        return devs
                    } catch (e) {
                        console.log("[Bluetooth] Error loading devices:", e)
                        return []
                    }
                })() : null

                delegate: BluetoothDeviceDelegate {
                    deviceName: modelData.name || "Unknown Device"
                    deviceAddress: modelData.address
                    deviceType: modelData.type || ""
                    isConnected: modelData.connected
                    isPaired: modelData.paired
                    isConnecting: btConnectProc.running && btConnectProc.targetAddress === modelData.address

                    onRequestConnect: function(addr) {
                        btConnectProc.targetAddress = addr
                        btConnectProc.running = true
                    }
                    onRequestDisconnect: function(addr) {
                        btDisconnectProc.targetAddress = addr
                        btDisconnectProc.running = true
                    }
                }
            }

            // Empty state (Scanning / No devices)
            Text {
                anchors.centerIn: parent
                visible: btListView.count === 0 && !isBlocked && btEnabled && !isScanning
                text: "No devices found"
                font.family: "Inter"
                font.pixelSize: 14
                color: Colors.m3.outline
            }
        }

        // ── Bluetooth Disabled / Empty state ───────────────────────────────────
        Column {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !btEnabled || isBlocked
            spacing: 16

            Item { Layout.fillHeight: true } // Spacer
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: isBlocked ? "󰂲" : "󰂲"
                font.family: "Material Design Icons"
                font.pixelSize: 48
                color: Colors.m3.on_surface_variant
                opacity: 0.6
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: isBlocked ? "Bluetooth is blocked" : "Bluetooth is turned off"
                font.family: "Inter"
                font.pixelSize: 16
                font.bold: true
                color: Colors.m3.on_surface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn it on to see available devices"
                font.family: "Inter"
                font.pixelSize: 13
                color: Colors.m3.on_surface_variant
                visible: !isBlocked
            }
            
            Item { Layout.fillHeight: true } // Spacer
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.m3.surface_container.r, Colors.m3.surface_container.g, Colors.m3.surface_container.b, 0.5)
        visible: isBusy
        z: 99
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
