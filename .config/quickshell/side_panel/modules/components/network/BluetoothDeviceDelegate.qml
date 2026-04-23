import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../../qs/services"

Rectangle {
    width: ListView.view ? ListView.view.width : parent.width
    height: 64
    radius: 12
    visible: deviceName !== ""
    
    property string deviceName: ""
    property string deviceAddress: ""
    property string deviceType: ""
    property bool isConnected: false
    property bool isPaired: false
    property bool isConnecting: false

    signal requestConnect(string address)
    signal requestDisconnect(string address)

    color: isConnected ? Colors.m3.secondary_container : (btMa.containsMouse ? Colors.m3.surface_container_highest : Colors.m3.surface_container)
    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 16

        Text {
            text: {
                const t = deviceType.toLowerCase()
                if (t.includes("audio") || t.includes("headset") || t.includes("headphone")) return "󰟤"
                if (t.includes("keyboard")) return "󰌨"
                if (t.includes("mouse")) return "󰍽"
                if (t.includes("phone")) return "󰌟"
                if (t.includes("speaker")) return "󰕓"
                if (t.includes("watch")) return "󰌔"
                return "󰂯"
            }
            font.family: "Material Design Icons"
            font.pixelSize: 22
            color: isConnected ? Colors.m3.on_secondary_container : Colors.m3.on_surface_variant
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: deviceName
                font.family: "Inter"
                font.pixelSize: 14
                font.bold: isConnected
                color: isConnected ? Colors.m3.on_secondary_container : Colors.m3.on_surface
            }
            Text {
                width: parent.width
                text: isConnected ? "Connected" : (isPaired ? "Paired" : "Available")
                font.family: "Inter"
                font.pixelSize: 12
                color: isConnected ? Colors.m3.primary : Colors.m3.on_surface_variant
            }
        }

        Rectangle {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 32
            radius: 16
            color: isConnected ? Colors.m3.error_container : Colors.m3.primary_container
            Text {
                anchors.centerIn: parent
                font.family: "Inter"
                font.pixelSize: 12
                font.bold: true
                text: isConnecting ? "..." : (isConnected ? "Disconnect" : "Connect")
                color: isConnected ? Colors.m3.on_error_container : Colors.m3.on_primary_container
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isConnected) {
                        requestDisconnect(deviceAddress)
                    } else {
                        requestConnect(deviceAddress)
                    }
                }
            }
        }
    }
    
    MouseArea {
        id: btMa
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: function(mouse) { mouse.accepted = false }
    }
}
