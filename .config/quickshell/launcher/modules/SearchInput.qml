import QtQuick
import Quickshell
import "../../qs/services"

Rectangle {
	id: root

    // Colors service — passed down from parent
    required property var colors

	width: parent.width
	height: 48
	radius: 24
	color: colors.m3.surface_container_high
	border.color: "transparent"
	border.width: 0

	// lets the parent read the typed text
	property alias text: input.text

    function forceActiveFocus() {
        input.forceActiveFocus();
    }

	signal upPressed
	signal downPressed
	signal acceptPressed
	signal escapePressed

    // Search Icon
    Text {
        id: searchIcon
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "search" // Material Icon
        color: colors.m3.on_surface_variant
        font.pixelSize: 20
        font.family: "Material Icons Round"
    }

	TextInput {
		id: input
		anchors.left: searchIcon.right
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		
		// Horizontal padding
		anchors.leftMargin: 12
		anchors.rightMargin: 16

		// Ensures text is centered inside its own bounding box
		verticalAlignment: TextInput.AlignVCenter

		color: colors.m3.on_surface
		font.pixelSize: 15
		font.family: "Inter"

        // Placeholder logic
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: "Search apps..."
            color: colors.m3.on_surface_variant
            font.pixelSize: 15
            font.family: "Inter"
            visible: input.text.length === 0
            opacity: 0.6
        }

		focus: true
		cursorVisible: true

		Keys.onUpPressed: root.upPressed()
		Keys.onDownPressed: root.downPressed()
		Keys.onReturnPressed: root.acceptPressed()
	
		// catch escape key to close the launcher
		Keys.onEscapePressed: root.escapePressed()
	}
}
