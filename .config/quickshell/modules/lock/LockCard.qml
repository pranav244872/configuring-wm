// Lock card: formation layout (user chip, big clock + date, password field
// with accent submit), our teal, JetBrains Mono. Real TextInput owns typing;
// auth lives in LockAuth, locking in LockHost.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.widgets
import qs.modules.lock

FocusScope {
    id: root

    required property LockAuth auth
    property var locker: null
    property string userName: Quickshell.env("USER") || "USER"

    // Guarded: surface properties arrive after first evaluation and vanish on
    // teardown; never dereference a null auth in a binding.
    readonly property bool hasAuth: root.auth !== null

    focus: true

    property string clockText: "--:--"
    property string dateText: ""
    property string weekdayText: ""

    implicitWidth: 408
    implicitHeight: frameRect.implicitHeight

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.tickClock()
    }

    Component.onCompleted: {
        root.tickClock();
        passwordInput.forceActiveFocus();
    }

    function tickClock() {
        const now = new Date();
        root.clockText = Qt.formatDateTime(now, "HH:mm");
        root.dateText = Qt.formatDateTime(now, "d MMM").toUpperCase();
        root.weekdayText = Qt.formatDateTime(now, "ddd // yyyy").toUpperCase();
    }

    function statusText() {
        if (!root.auth)
            return "";
        if (root.auth.busy)
            return "VERIFYING ...";
        if (root.auth.lockMessage !== "")
            return root.auth.lockMessage;
        if (root.auth.state === LockAuth.State.Failed)
            return "WRONG PASSWORD";
        if (root.auth.state === LockAuth.State.Error)
            return "AUTH ERROR";
        if (root.auth.state === LockAuth.State.MaxTries)
            return "TOO MANY TRIES";
        return "";
    }

    function forceInputFocus() {
        passwordInput.forceActiveFocus();
    }

    Rectangle {
        id: frameRect
        anchors.centerIn: parent
        width: 408
        // 40px accounts for loginCol's top/bottom Layout.margins (20 + 20), + 2px border
        implicitHeight: loginCol.implicitHeight + 42
        height: implicitHeight
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline

        CornerTicks {
            anchors.fill: parent
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left accent spine with vertical label
            Rectangle {
                Layout.preferredWidth: 56
                Layout.fillHeight: true
                color: Theme.colors.primary

                StyledText {
                    anchors.centerIn: parent
                    rotation: 90
                    text: "LOCKED"
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.titleTrack
                    color: Theme.colors.fgPrimary
                }
            }

            ColumnLayout {
                id: loginCol
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 14

                // User row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    StyledText {
                        text: "USER"
                        font.pixelSize: Theme.frame.labelSize
                        font.letterSpacing: 1
                        color: Theme.colors.subtext
                    }

                    StyledText {
                        text: "//"
                        font.pixelSize: Theme.frame.labelSize
                        color: Theme.colors.primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: root.userName.toUpperCase()
                        font.pixelSize: Theme.font.size.sm
                        font.weight: Font.DemiBold
                        color: Theme.colors.fgLayer0
                    }
                }

                // Clock + date row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    StyledText {
                        text: root.clockText
                        font.pixelSize: 40
                        font.weight: Font.Medium
                        color: Theme.colors.fgLayer0
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 38
                        color: Theme.colors.outline
                    }

                    ColumnLayout {
                        spacing: 3

                        StyledText {
                            text: root.dateText
                            font.pixelSize: Theme.font.size.sm
                            color: Theme.colors.fgLayer0
                        }

                        StyledText {
                            text: root.weekdayText
                            font.pixelSize: Theme.frame.labelSize
                            font.letterSpacing: 1
                            color: Theme.colors.subtext
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.colors.outline
                }

                // Password header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    StyledText {
                        text: "PASSWORD"
                        font.pixelSize: Theme.frame.labelSize
                        font.letterSpacing: 1
                        color: Theme.colors.subtext
                    }

                    StyledText {
                        text: "//"
                        font.pixelSize: Theme.frame.labelSize
                        color: Theme.colors.primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                // Password input box
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    clip: true
                    color: Theme.colors.layer1
                    border.width: Theme.frame.line
                    border.color: (root.hasAuth && root.auth.state !== LockAuth.State.None)
                        ? Theme.colors.error
                        : (passwordInput.activeFocus ? Theme.colors.primary : Theme.colors.outline)

                    Rectangle {
                        width: 2
                        height: parent.height
                        color: (root.hasAuth && root.auth.state !== LockAuth.State.None) ? Theme.colors.error : Theme.colors.primary
                    }

                    // Real TextInput so seat keyboard + backspace + Enter work
                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 54
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        clip: true
                        enabled: root.hasAuth && !root.auth.busy && root.auth.state !== LockAuth.State.MaxTries
                        echoMode: TextInput.Password
                        passwordCharacter: "*"
                        color: Theme.colors.fgLayer0
                        font.family: Theme.font.main
                        font.pixelSize: Theme.font.size.md
                        font.letterSpacing: 3
                        text: root.hasAuth ? root.auth.buffer : ""

                        onTextChanged: {
                            if (root.auth.buffer !== text)
                                root.auth.buffer = text;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                root.auth.buffer = "";
                                passwordInput.text = "";
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.auth.submit();
                                event.accepted = true;
                            }
                        }

                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "TYPE PASSWORD ..."
                            font.pixelSize: Theme.font.size.sm
                            font.letterSpacing: Theme.frame.tracking
                            color: Theme.colors.subtext
                            opacity: 0.6
                            visible: passwordInput.text.length === 0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 44
                        cursorShape: Qt.IBeamCursor
                        onClicked: passwordInput.forceActiveFocus()
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 44
                        height: parent.height
                        color: submitMa.containsMouse ? ColorUtils.lighten(Theme.colors.primary, 0.15) : Theme.colors.primary

                        StyledText {
                            anchors.centerIn: parent
                            text: "keyboard_return"
                            font.family: Theme.font.icon
                            font.pixelSize: 20
                            color: Theme.colors.fgPrimary
                        }

                        MouseArea {
                            id: submitMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.auth.submit();
                                passwordInput.forceActiveFocus();
                            }
                        }
                    }
                }

                // Fixed-height status line so card doesn't jump on error
                StyledText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    text: root.statusText()
                    font.pixelSize: Theme.frame.labelSize
                    font.letterSpacing: Theme.frame.tracking
                    color: (root.hasAuth && root.auth.busy) ? Theme.colors.primary : Theme.colors.error
                }

                // TEMPORARY debug hatch: sets locker.locked = false (no PAM)
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.fillWidth: true
                    color: tempMa.containsMouse ? Theme.colors.primaryContainer : "transparent"
                    border.width: Theme.frame.line
                    border.color: Theme.colors.error

                    StyledText {
                        anchors.centerIn: parent
                        text: "TEMP UNLOCK (DEBUG)"
                        font.pixelSize: Theme.frame.labelSize
                        font.letterSpacing: Theme.frame.tracking
                        color: Theme.colors.error
                    }

                    MouseArea {
                        id: tempMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.locker)
                                root.locker.locked = false;
                        }
                    }
                }
            }
        }
    }
}
