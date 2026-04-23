// SearchBar.qml — Search input with icon and clear button
//
// Caelestia-style pill-shaped search bar:
//   - Short and wide (36px height, full width)
//   - Full rounded corners (pill shape)
//   - m3surfaceContainerLow background
//   - Material Icons for search and close
//   - Search icon on the left
//   - Text input in the center
//   - Clear button (X) on the right
//
// Signals:
//   acceptPressed   — Enter pressed
//   escapePressed   — Escape pressed
//   leftPressed     — Left arrow pressed (for carousel navigation)
//   rightPressed    — Right arrow pressed (for carousel navigation)

import QtQuick

Rectangle {
    id: root

    required property var colors

    height: 36
    radius: 18 // Pill shape (half of height)
    color: colors.m3.surface_container_low
    border.color: colors.m3.outline_variant
    border.width: 1

    // Expose the text to parent components
    property alias text: input.text

    // Signals for key events
    signal acceptPressed
    signal escapePressed
    signal leftPressed
    signal rightPressed

    // Search icon on the left (Material Icons)
    Text {
        id: searchIcon
        anchors {
            left: parent.left
            leftMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: "search"
        color: colors.m3.on_surface_variant
        font.pixelSize: 18
        font.family: "Material Icons Round"
    }

    // Placeholder text (shown when input is empty and not focused)
    Text {
        anchors {
            left: searchIcon.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: "search wallpapers..."
        color: colors.m3.outline
        font.pixelSize: 12
        font.family: "Rubik"
        visible: input.text.length === 0 && !input.activeFocus
    }

    // Text input
    TextInput {
        id: input
        anchors {
            left: searchIcon.right
            right: clearButton.left
            leftMargin: 8
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }

        color: colors.m3.on_surface
        font.pixelSize: 12
        font.family: "Rubik"

        focus: true
        cursorVisible: true
        verticalAlignment: TextInput.AlignVCenter

        Keys.onReturnPressed: root.acceptPressed()
        Keys.onEscapePressed: root.escapePressed()
        Keys.onLeftPressed: {
            if (input.text.length === 0 || input.cursorPosition === 0) {
                root.leftPressed()
            }
        }
        Keys.onRightPressed: {
            if (input.cursorPosition === input.text.length) {
                root.rightPressed()
            }
        }
    }

    // Clear button (X) — only visible when there's text
    Rectangle {
        id: clearButton
        width: 24
        height: 24
        radius: 12
        color: clearMouse.pressed ? colors.m3.surface_container_highest : "transparent"

        anchors {
            right: parent.right
            rightMargin: 6
            verticalCenter: parent.verticalCenter
        }

        visible: input.text.length > 0

        Text {
            anchors.centerIn: parent
            text: "close"
            color: colors.m3.outline
            font.pixelSize: 16
            font.family: "Material Icons Round"
            opacity: clearMouse.containsMouse ? 1 : 0.7
        }

        MouseArea {
            id: clearMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: input.text = ""
        }
    }
}
