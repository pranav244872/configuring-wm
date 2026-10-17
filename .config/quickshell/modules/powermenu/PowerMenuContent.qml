// Power menu body: tracked header + rule, session entries, rule + hint.
// Shared by PowerMenuHost and the preview bench.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import qs.modules.powermenu

FocusScope {
    id: root

    signal activated(var command)
    signal dismissed()

    focus: true

    // Height follows the content: the panel is sized to the menu, never the
    // screen. The window wrapper reads this to size itself.
    implicitHeight: col.implicitHeight

    // Pin one row's hover state; -1 = follow the real pointer (previews only).
    property int activeIndex: -1

    // Session actions in menu order. `command` is an argv array (execDetached),
    // never a shell string. Log out uses the fork's Lua dispatch form -- hyprctl
    // rejects the bare legacy dispatcher name ("expected a dispatcher").
    readonly property var entries: [
        {
            glyph: Theme.glyphs.powerLock,
            label: "LOCK",
            command: ["qs", "ipc", "call", "lock", "lock"]
        },
        {
            glyph: Theme.glyphs.powerLogout,
            label: "LOG OUT",
            command: ["hyprctl", "dispatch", "hl.dsp.exit()"]
        },
        {
            glyph: Theme.glyphs.powerSuspend,
            label: "SUSPEND",
            command: ["systemctl", "suspend"]
        },
        {
            glyph: Theme.glyphs.powerReboot,
            label: "REBOOT",
            command: ["systemctl", "reboot"]
        },
        {
            glyph: Theme.glyphs.powerShutdown,
            label: "SHUT DOWN",
            command: ["systemctl", "poweroff"]
        }
    ]

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.dismissed();
            event.accepted = true;
        }
    }

    component Rule: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.frame.line
        color: Theme.colors.outline
    }

    component MicroLabel: StyledText {
        font.pixelSize: Theme.frame.labelSize
        font.letterSpacing: Theme.frame.tracking
        color: Theme.colors.subtext
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MicroLabel {
                text: "SESSION"
            }

            Item {
                Layout.fillWidth: true
            }

            MicroLabel {
                text: String(root.entries.length).padStart(2, "0")
                color: Theme.colors.primary
            }
        }

        Rule {
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: root.entries

                delegate: PowerMenuItem {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    glyph: modelData.glyph
                    label: modelData.label
                    forceActive: root.activeIndex === index
                    onActivated: root.activated(modelData.command)
                }
            }
        }

        Rule {
        }

        MicroLabel {
            Layout.alignment: Qt.AlignHCenter
            text: "ESC // CLOSE"
        }
    }
}
