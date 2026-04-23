// UserInfoCard.qml — User and system info card
//
// Shows username, hostname, kernel, shell, uptime.
// Data gathered via Process + StdioCollector.

import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: card

    required property var colors
    color: colors.m3.surface_container
    radius: 16

    property string username: ""
    property string hostname: ""
    property string kernel: ""
    property string shell: ""
    property string uptime: ""

    Timer {
        id: initTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            whoamiProcess.running = true
            hostnameProcess.running = true
            kernelProcess.running = true
            shellProcess.running = true
            uptimeProcess.running = true
        }
    }

    Timer {
        id: uptimeTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            uptimeProcess.running = true
        }
    }

    Process {
        id: whoamiProcess
        command: ["bash", "-c", "whoami"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                card.username = text.trim()
            }
        }
    }

    Process {
        id: hostnameProcess
        command: ["bash", "-c", "uname -n"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                card.hostname = text.trim()
            }
        }
    }

    Process {
        id: kernelProcess
        command: ["bash", "-c", "uname -r"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                card.kernel = text.trim()
            }
        }
    }

    Process {
        id: shellProcess
        command: ["bash", "-c", "basename $SHELL"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                card.shell = text.trim()
            }
        }
    }

    Process {
        id: uptimeProcess
        command: ["bash", "-c", "uptime -p"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                card.uptime = text.trim()
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Row {
            spacing: 6

            Text {
                text: "person"
                color: card.colors.m3.primary
                font.pixelSize: 16
                font.family: "Material Icons Round"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "System Info"
                color: card.colors.m3.on_surface
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            spacing: 4
            width: parent.width

            component InfoRow: Row {
                id: rowRoot
                spacing: 8
                width: parent.width
                property string icon: ""
                property string label: ""
                property string sub: ""

                Text {
                    text: rowRoot.icon
                    color: card.colors.m3.on_surface_variant
                    font.pixelSize: 14
                    font.family: "Material Icons Round"
                    width: 18
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    spacing: 0

                    Text {
                        text: rowRoot.label
                        color: card.colors.m3.on_surface
                        font.pixelSize: 12
                        font.family: "Inter"
                        font.weight: Font.Medium
                    }

                    Text {
                        text: rowRoot.sub
                        color: card.colors.m3.on_surface_variant
                        font.pixelSize: 10
                        font.family: "Inter"
                    }
                }
            }

            InfoRow { icon: "account_circle"; label: card.username || "Loading..."; sub: "User" }
            InfoRow { icon: "dns"; label: card.hostname || "Loading..."; sub: "Host" }
            InfoRow { icon: "terminal"; label: card.kernel || "Loading..."; sub: "Kernel" }
            InfoRow { icon: "code"; label: card.shell || "Loading..."; sub: "Shell" }
            InfoRow { icon: "schedule"; label: card.uptime || "Loading..."; sub: "Uptime" }
        }
    }
}
