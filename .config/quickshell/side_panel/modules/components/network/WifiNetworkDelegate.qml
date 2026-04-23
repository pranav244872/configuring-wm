import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../../qs/services"

ColumnLayout {
    id: rootWifiDel
    width: ListView.view ? ListView.view.width : 300
    spacing: 0

    property string ssid: ""
    property int signalStr: 0
    property bool isActive: false
    property bool isSecure: false
    property bool isSaved: false
    property bool isExpanded: false

    signal requestExpand(string reqSsid)
    signal requestConnect(string reqSsid, string password)
    signal requestDisconnect(string reqSsid)

    function handleRowClick() {
        if (!isActive) {
            if (!isSaved && isSecure) {
                requestExpand(ssid)
            } else {
                requestConnect(ssid, "")
            }
        }
        // If isActive, do nothing on row click (disconnect must be explicit via button)
    }

    function handleActionClick() {
        if (isActive) {
            requestDisconnect(ssid)
        } else {
            if (!isSaved && isSecure) {
                requestExpand(ssid)
            } else {
                requestConnect(ssid, "")
            }
        }
    }

    Rectangle {
        id: networkRect
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 12
        color: isActive ? Colors.m3.secondary_container : Colors.m3.surface_container
        // Manually handle hover color via rowMa below
        Behavior on color { ColorAnimation { duration: 150 } }

        MouseArea {
            id: rowMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onContainsMouseChanged: {
                if (!isActive) {
                    networkRect.color = containsMouse ? Colors.m3.surface_container_highest : Colors.m3.surface_container
                }
            }
            onClicked: handleRowClick()
        }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 16

            Text {
                text: signalStr > 80 ? "󰤨" : signalStr > 60 ? "󰤥" : signalStr > 40 ? "󰤢" : "󰤟"
                font.family: "Material Design Icons"
                font.pixelSize: 22
                color: isActive ? Colors.m3.on_secondary_container : Colors.m3.on_surface_variant
            }
            
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: ssid
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.bold: isActive
                    color: isActive ? Colors.m3.on_secondary_container : Colors.m3.on_surface
                }
                RowLayout {
                    spacing: 6
                    Text {
                        text: "󰦝"
                        font.family: "Material Design Icons"
                        font.pixelSize: 12
                        color: Colors.m3.on_surface_variant
                        visible: isSecure
                    }
                    Text {
                        text: isActive ? "Connected" : (isSecure ? "Secured" : "Open")
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: isActive ? Colors.m3.primary : Colors.m3.on_surface_variant
                    }
                }
            }

            Rectangle {
                id: actionBtn
                Layout.preferredWidth: 90
                Layout.preferredHeight: 32
                radius: 16
                visible: !(!isActive && isExpanded) // Hide duplicate connect button when password prompt is open
                color: actionMa.containsMouse 
                        ? (isActive ? Colors.m3.error : Colors.m3.primary)
                        : (isActive ? Colors.m3.error_container : Colors.m3.primary_container)
                Behavior on color { ColorAnimation { duration: 120 } }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                    text: isActive ? "Disconnect" : "Connect"
                    color: actionMa.containsMouse
                            ? (isActive ? Colors.m3.on_error : Colors.m3.on_primary)
                            : (isActive ? Colors.m3.on_error_container : Colors.m3.on_primary_container)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: actionMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: handleActionClick()
                }
            }
        }
    }

    // Properly layered Row interaction
    Component.onCompleted: {
        // We move the rowMa above the background to catch clicks, but below the button.
        // Handled naturally by QML z-ordering, so I will bind color explicitly.
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: isExpanded ? 56 : 0
        Layout.topMargin: isExpanded ? 4 : 0
        opacity: isExpanded ? 1.0 : 0.0
        color: "transparent"
        clip: true
        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on Layout.topMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: Colors.m3.surface_container_highest
                border.color: pwInput.activeFocus ? Colors.m3.primary : Colors.m3.outline
                border.width: pwInput.activeFocus ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: pwInput
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "Inter"
                    font.pixelSize: 13
                    color: Colors.m3.on_surface
                    echoMode: TextInput.Password
                    clip: true
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter Password"
                        color: Colors.m3.outline
                        font.family: "Inter"
                        font.pixelSize: 13
                        visible: !pwInput.text && !pwInput.activeFocus
                    }
                    
                    Keys.onEnterPressed: requestConnect(ssid, pwInput.text)
                    Keys.onReturnPressed: requestConnect(ssid, pwInput.text)
                }
            }
            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 36
                radius: 18
                color: promptConnectMa.containsMouse ? Colors.m3.primary : Colors.m3.primary_container
                Behavior on color { ColorAnimation { duration: 120 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.bold: true
                    color: promptConnectMa.containsMouse ? Colors.m3.on_primary : Colors.m3.on_primary_container
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    id: promptConnectMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: requestConnect(ssid, pwInput.text)
                }
            }
        }
    }
}
