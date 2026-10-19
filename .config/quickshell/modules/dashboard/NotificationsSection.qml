// Notifications section: the DND switch and the session's toast history.
//
// Rows reuse NotificationCard, so what the sheet shows is exactly what was on
// screen -- minus the countdown, which means nothing once the toast is gone.
// The entries are plain data (the notification objects behind them were
// destroyed when they left the screen), so a row cannot be clicked through.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.widgets
import qs.modules.notifications

Item {
    id: root

    readonly property var entries: NotificationService.history

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ---------------- header ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                text: "NOTIFICATIONS"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                visible: root.entries.length > 0
                text: root.entries.length.toString().padStart(2, "0")
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.primary
            }

            StyledText {
                id: clearLabel
                Layout.alignment: Qt.AlignVCenter
                visible: root.entries.length > 0
                text: "CLEAR"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: clearMa.containsMouse ? Theme.colors.primary : Theme.colors.fgLayer0

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animation.valueDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.animation.curveOut
                    }
                }

                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearHistory()
                }
            }

            Toggle {
                Layout.alignment: Qt.AlignVCenter
                checked: NotificationService.doNotDisturb
                onToggled: NotificationService.toggleDnd()
            }
        }

        // ---------------- rule ----------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.frame.line
            color: Theme.colors.outline
        }

        // ---------------- history ----------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                visible: root.entries.length > 0
                clip: true
                spacing: 4
                topMargin: 4
                bottomMargin: 4
                model: root.entries

                delegate: NotificationCard {
                    required property var modelData

                    width: list.width
                    clickable: false
                    app: modelData.app
                    appIcon: modelData.appIcon
                    summary: modelData.summary
                    body: modelData.body
                    image: modelData.image
                    urgency: modelData.urgency

                    onCloseRequested: NotificationService.removeHistory(modelData)
                }
            }

            // DND is the reason a notification can be missing from the list, so
            // the empty state says which of the two it is.
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.entries.length === 0

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: NotificationService.doNotDisturb ? Theme.glyphs.notifDnd : Theme.glyphs.notifBell
                    font.family: Theme.font.icon
                    font.pixelSize: 28
                    color: Theme.colors.subtext
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: NotificationService.doNotDisturb ? "DO NOT DISTURB IS ON" : "NOTHING YET"
                    font.pixelSize: Theme.font.size.sm
                    font.letterSpacing: Theme.frame.tracking
                    color: Theme.colors.subtext
                }
            }
        }
    }
}
