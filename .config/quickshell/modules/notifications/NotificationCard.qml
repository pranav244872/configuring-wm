// Notification card: one notification, drawn once and reused by the toast
// stack (NotificationHost) and the dashboard's history list.
//
// Presentation only: the lifetime, the hover pause and the model live outside
// (the host's delegate owns the countdown, the service owns the data), so the
// preview bench can render any state from plain properties.
//
// Text is verbatim data -- app names and bodies are not labels, so they are
// not uppercased. The body is PlainText on purpose: `Text` is AutoText, so a
// body could otherwise smuggle in markup even though the server does not
// advertise any (see gotchas.md).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.modules
import qs.modules.widgets

Rectangle {
    id: root

    // Snapshot fields (plain data, never a live Notification object).
    property string app: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string image: ""

    // NotificationUrgency.Normal == 1
    property int urgency: 1

    // Countdown drain: 1 -> 0. Negative hides the bar (history rows have no
    // clock to run down).
    property real progress: -1

    // Arrival time, drawn at the right end of the app line when `showTime` is
    // set. Off for toasts (a toast is happening now), on for history rows,
    // where the timestamp anchors an otherwise very wide line.
    property real timestamp: 0
    property bool showTime: false

    readonly property string timeText: root.showTime && root.timestamp > 0
                                       ? Qt.formatTime(new Date(root.timestamp), "HH:mm") : ""

    property bool closable: true

    // Pointer feedback only; the consumer decides what a click does.
    property bool clickable: true

    signal closeRequested()
    signal cardClicked()

    readonly property alias hovered: area.containsMouse
    readonly property bool critical: root.urgency === 2
    readonly property bool low: root.urgency === 0

    // Critical is the only urgency that gets the alarm colour; low is a
    // background notification and reads quieter than normal.
    readonly property color accent: root.critical ? Theme.colors.error
                                    : (root.low ? Theme.colors.subtext : Theme.colors.primary)

    readonly property int pad: 10

    implicitWidth: Theme.notifications.width
    implicitHeight: column.implicitHeight + 2 * root.pad

    color: Theme.colors.layer0
    border.width: Theme.frame.line
    border.color: Theme.colors.outline

    // The card-wide click catcher is declared BEFORE the content on purpose:
    // later siblings stack above earlier ones and get input first, so an
    // area declared after the column would swallow every click meant for the
    // close button (the ✕ did nothing in the dashboard until 2026-10-19).
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton)
                root.closeRequested();
            else
                root.cardClicked();
        }
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Avatar (or the app's icon, or the bell): a fixed slot so every
            // card's text starts at the same x.
            Item {
                id: avatarBox

                Layout.preferredWidth: Theme.notifications.avatar
                Layout.preferredHeight: Theme.notifications.avatar
                Layout.alignment: Qt.AlignTop

                readonly property string resolved: root.image.length > 0
                                                    ? root.image
                                                    : (root.appIcon.length > 0
                                                       ? Quickshell.iconPath(root.appIcon, true) : "")

                IconImage {
                    id: avatar
                    anchors.fill: parent
                    asynchronous: true
                    source: avatarBox.resolved
                    visible: avatarBox.resolved.length > 0 && status !== Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !avatar.visible
                    color: Theme.colors.stateHover

                    Glyph {
                        anchors.centerIn: parent
                        text: Theme.glyphs.notifBell
                        color: root.accent
                        font.pixelSize: 17
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    visible: root.app.length > 0
                    text: root.app
                    color: Theme.colors.subtext
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.tracking
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.summary.length > 0
                    text: root.summary
                    color: Theme.colors.fgLayer0
                    font.pixelSize: Theme.font.size.sm
                    font.weight: Font.DemiBold
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.body.length > 0
                    text: root.body
                    textFormat: Text.PlainText
                    color: Theme.colors.subtext
                    font.pixelSize: Theme.font.size.xs
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: Theme.notifications.bodyLines
                    elide: Text.ElideRight
                }
            }

            StyledText {
                id: timeLabel

                Layout.alignment: Qt.AlignTop
                visible: root.timeText.length > 0
                text: root.timeText
                color: Theme.colors.subtext
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
            }

            StyledText {
                id: closeGlyph

                Layout.alignment: Qt.AlignTop
                visible: root.closable
                text: Theme.glyphs.notifClose
                font.family: Theme.font.icon
                font.pixelSize: 15
                color: closeArea.containsMouse ? Theme.colors.primary : Theme.colors.subtext
                opacity: root.hovered || closeArea.containsMouse ? 1 : 0.45

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animation.valueDuration
                    }
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // Drain track (hairline, like every other rule in our frame).
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.frame.line
            visible: root.progress >= 0

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.barTrack
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                color: root.accent
            }
        }
    }

    // Urgency strip, hard against the left edge.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 2
        color: root.accent
        opacity: root.low ? 0.5 : 1
    }

    CornerTicks {
        anchors.fill: parent
    }
}
