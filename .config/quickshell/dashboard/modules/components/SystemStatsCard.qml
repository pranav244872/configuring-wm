// SystemStatsCard.qml — CPU and RAM usage with progress bars
//
// Vertical progress bars with percentage labels.
// Polls /proc/stat for CPU and `free` for RAM every 2 seconds.
// Also shows top 3 processes by CPU usage.

import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: card

    required property var colors
    color: colors.m3.surface_container
    radius: 16

    property int cpuUsage: 0
    property int ramUsage: 0
    property int ramUsed: 0
    property int ramTotal: 0

    // CPU polling via /proc/stat
    property int prevIdle: 0
    property int prevTotal: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProcess.running = true
            ramProcess.running = true
        }
    }

    Process {
        id: cpuProcess
        command: ["bash", "-c", "read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; total=$((user + nice + system + idle + iowait + irq + softirq + steal)); idle=$((idle + iowait)); echo \"$total $idle\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                const total = parseInt(parts[0]) || 0
                const idle = parseInt(parts[1]) || 0
                if (card.prevTotal > 0) {
                    const diffTotal = total - card.prevTotal
                    const diffIdle = idle - card.prevIdle
                    if (diffTotal > 0) {
                        card.cpuUsage = Math.round(((diffTotal - diffIdle) / diffTotal) * 100)
                    }
                }
                card.prevTotal = total
                card.prevIdle = idle
            }
        }
    }

    Process {
        id: ramProcess
        command: ["bash", "-c", "free -m | awk '/^Mem:/ {printf \"%d %d\", $3, $2}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                card.ramUsed = parseInt(parts[0]) || 0
                card.ramTotal = parseInt(parts[1]) || 0
                if (card.ramTotal > 0) {
                    card.ramUsage = Math.round((card.ramUsed / card.ramTotal) * 100)
                }
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Title
        Row {
            spacing: 6

            Text {
                text: "memory"
                color: card.colors.m3.primary
                font.pixelSize: 16
                font.family: "Material Icons Round"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "System Resources"
                color: card.colors.m3.on_surface
                font.pixelSize: 13
                font.family: "Inter"
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // CPU bar
        Item {
            width: parent.width
            height: cpuBarRow.height + 10

            Row {
                id: cpuBarRow
                width: parent.width
                spacing: 4

                Text {
                    text: "memory"
                    color: card.colors.m3.on_surface_variant
                    font.pixelSize: 14
                    font.family: "Material Icons Round"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "CPU"
                    color: card.colors.m3.on_surface
                    font.pixelSize: 12
                    font.family: "Inter"
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: card.cpuUsage + "%"
                    color: cpuBar.color
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                anchors.top: cpuBarRow.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                height: 6
                radius: 3
                color: card.colors.m3.surface_container_highest

                Rectangle {
                    id: cpuBar
                    height: parent.height
                    width: parent.width * (card.cpuUsage / 100)
                    radius: 3
                    color: {
                        if (card.cpuUsage > 80) return card.colors.m3.error
                        if (card.cpuUsage > 60) return card.colors.m3.tertiary
                        return card.colors.m3.primary
                    }
                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        // RAM bar
        Item {
            width: parent.width
            height: ramBarRow.height + 10

            Row {
                id: ramBarRow
                width: parent.width
                spacing: 4

                Text {
                    text: "developer_board"
                    color: card.colors.m3.on_surface_variant
                    font.pixelSize: 14
                    font.family: "Material Icons Round"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "RAM"
                    color: card.colors.m3.on_surface
                    font.pixelSize: 12
                    font.family: "Inter"
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: card.ramUsage + "%  (" + card.ramUsed + "/" + card.ramTotal + " MB)"
                    color: ramBar.color
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                anchors.top: ramBarRow.bottom
                anchors.topMargin: 4
                anchors.left: parent.left
                anchors.right: parent.right
                height: 6
                radius: 3
                color: card.colors.m3.surface_container_highest

                Rectangle {
                    id: ramBar
                    height: parent.height
                    width: parent.width * (card.ramUsage / 100)
                    radius: 3
                    color: {
                        if (card.ramUsage > 90) return card.colors.m3.error
                        if (card.ramUsage > 75) return card.colors.m3.tertiary
                        return card.colors.m3.primary
                    }
                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
}
