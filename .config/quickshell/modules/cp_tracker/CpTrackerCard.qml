// ~/.config/quickshell/modules/cp_tracker/CpTrackerCard.qml
// Competitive Programming desktop tracker card matching Chaldea design system.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules
import qs.modules.widgets

Item {
    id: root

    property real boundW: 1920
    property real boundH: 1080

    signal dragFinished()
    readonly property bool dragging: dragArea.drag.active

    // Card dimensions match CalendarCard (320px wide)
    implicitWidth: 320
    implicitHeight: col.implicitHeight + 32

    // Internal tracker state
    property var trackerData: null
    property bool isLoading: false
    property int minuteTick: 0

    // Refresh every 15 minutes
    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchData(false)
    }

    // Refresh minute ticker
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.minuteTick++
    }

    readonly property string cachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell/cp_data.json"
    readonly property string toolScript: Quickshell.env("HOME") + "/.config/quickshell/tools/cp_tracker.py"

    Component.onCompleted: {
        cacheLoader.running = true;
    }

    function fetchData(force) {
        if (networkProcess.running)
            return;
        root.isLoading = true;
        networkProcess.command = ["python3", root.toolScript, "--json"];
        networkProcess.running = true;
    }

    function parseResponse(text) {
        root.isLoading = false;
        if (!text || text.trim().length === 0)
            return;
        try {
            const parsed = JSON.parse(text);
            if (parsed && parsed.status === "success") {
                root.trackerData = parsed;
            }
        } catch (e) {
            console.log("CP Tracker parse error:", e);
        }
    }

    // Instant local disk read
    Process {
        id: cacheLoader
        command: ["sh", "-c", "cat \"" + root.cachePath + "\" 2>/dev/null || echo {}"]
        stdout: StdioCollector {
            id: cacheOut
            onStreamFinished: {
                root.parseResponse(cacheOut.text);
                if (!root.trackerData) {
                    root.fetchData(false);
                }
            }
        }
    }

    // Network background fetch
    Process {
        id: networkProcess
        stdout: StdioCollector {
            id: networkOut
            onStreamFinished: root.parseResponse(networkOut.text)
        }
    }

    Rectangle {
        id: widget
        anchors.fill: parent
        radius: 0
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline

        CornerTicks {
            anchors.fill: parent
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.threshold: 6
            drag.smoothed: true
            drag.filterChildren: true
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: root.boundW - root.width
            drag.maximumY: root.boundH - root.height
            onReleased: root.dragFinished()
        }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ============================================================== HEADER
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    text: "CP TRACKER"
                    font.pixelSize: Theme.font.size.md
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.frame.titleTrack
                }

                Item {
                    Layout.fillWidth: true
                }

                // Refresh Button
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 0
                    color: refreshMa.containsMouse ? Theme.colors.stateHover : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: Theme.glyphs.shotReselect
                        font.family: Theme.font.icon
                        font.pixelSize: 18
                        color: root.isLoading ? Theme.colors.primary : Theme.colors.subtext

                        RotationAnimation on rotation {
                            running: root.isLoading
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }

                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fetchData(true)
                    }
                }
            }

            // ============================================================== USER RATINGS
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                color: Theme.colors.layer1
                border.width: Theme.frame.line
                border.color: Theme.colors.outline

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    // Codeforces Block
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: "CODEFORCES"
                            font.pixelSize: Theme.font.size.xs
                            color: Theme.colors.subtext
                            font.weight: Font.Bold
                        }

                        StyledText {
                            text: root.trackerData ? root.trackerData.user.cf_handle : "pranav244872"
                            font.pixelSize: Theme.font.size.sm
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.colors.primary
                            }
                            StyledText {
                                text: root.trackerData ? (root.trackerData.user.cf_rating + " (" + root.trackerData.user.cf_rank + ")") : "0 (Unrated)"
                                font.pixelSize: Theme.font.size.xs
                                color: Theme.colors.subtext
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: Theme.frame.line
                        Layout.fillHeight: true
                        color: Theme.colors.outline
                    }

                    // AtCoder Block
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: "ATCODER"
                            font.pixelSize: Theme.font.size.xs
                            color: Theme.colors.subtext
                            font.weight: Font.Bold
                        }

                        StyledText {
                            text: root.trackerData ? root.trackerData.user.ac_handle : "pranav244872"
                            font.pixelSize: Theme.font.size.sm
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 4
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.palette.tertiary
                            }
                            StyledText {
                                text: root.trackerData ? (root.trackerData.user.ac_rating + " (" + root.trackerData.user.ac_rank + ")") : "0 (Unrated)"
                                font.pixelSize: Theme.font.size.xs
                                color: Theme.colors.subtext
                            }
                        }
                    }
                }
            }

            // ============================================================== FEATURED MATCH
            Rectangle {
                id: featuredBox
                Layout.fillWidth: true
                Layout.preferredHeight: featuredCol.implicitHeight + 16
                color: Theme.colors.layer1
                border.width: Theme.frame.line
                border.color: Theme.colors.primary

                readonly property var contest: root.trackerData ? root.trackerData.featured_contest : null

                ColumnLayout {
                    id: featuredCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        StyledText {
                            text: "NEXT TARGET MATCH"
                            font.pixelSize: Theme.font.size.xs
                            color: Theme.colors.primary
                            font.weight: Font.Bold
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: badgeText.implicitWidth + 8
                            color: Theme.colors.primaryContainer
                            radius: 2

                            StyledText {
                                id: badgeText
                                anchors.centerIn: parent
                                text: featuredBox.contest ? featuredBox.contest.badge : "⭐ Recommended"
                                font.pixelSize: 10
                                color: Theme.colors.fgPrimaryContainer
                                font.weight: Font.Bold
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: featuredBox.contest ? featuredBox.contest.name : "No Upcoming Target"
                        font.pixelSize: Theme.font.size.sm
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        StyledText {
                            text: featuredBox.contest ? featuredBox.contest.countdown : "--"
                            font.pixelSize: Theme.font.size.xl
                            font.weight: Font.Bold
                            color: Theme.colors.primary
                        }

                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: featuredBox.contest ? featuredBox.contest.start_formatted : "--"
                                font.pixelSize: Theme.font.size.xs
                                color: Theme.colors.fgLayer0
                            }
                            StyledText {
                                text: (featuredBox.contest ? featuredBox.contest.duration_str : "120m") + " duration"
                                font.pixelSize: 10
                                color: Theme.colors.subtext
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.contest && parent.contest.url) {
                            Qt.openUrlExternally(parent.contest.url);
                        }
                    }
                }
            }

            // ============================================================== UPCOMING CONTESTS LIST
            StyledText {
                text: "UPCOMING CONTESTS"
                font.pixelSize: Theme.font.size.xs
                color: Theme.colors.subtext
                font.weight: Font.Bold
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: (root.trackerData && root.trackerData.upcoming_contests) ? root.trackerData.upcoming_contests.slice(0, 4) : []

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: rowMa.containsMouse ? Theme.colors.stateHover : "transparent"
                        border.width: Theme.frame.line
                        border.color: ColorUtils.transparentize(Theme.colors.outline, 0.4)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 6

                            // Platform Tag
                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 16
                                radius: 2
                                color: modelData.platform === "Codeforces" ? Theme.colors.layer2 : Theme.colors.primaryContainer

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData.platform === "Codeforces" ? "CF" : "AC"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: modelData.platform === "Codeforces" ? Theme.colors.fgLayer0 : Theme.colors.fgPrimaryContainer
                                }
                            }

                            // Name
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Theme.font.size.xs
                                elide: Text.ElideRight
                            }

                            // Start / Countdown
                            StyledText {
                                text: modelData.countdown
                                font.pixelSize: Theme.font.size.xs
                                color: modelData.tier === "RECOMMENDED" ? Theme.colors.primary : Theme.colors.subtext
                                font.weight: modelData.tier === "RECOMMENDED" ? Font.Bold : Font.Normal
                            }
                        }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }
        }
    }
}
