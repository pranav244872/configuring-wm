import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../qs/services"

PanelWindow {
    id: window
    color: "transparent"
    visible: false

    property bool isOpen: false

    function toggle() {
        if (isOpen) close();
        else open();
    }

    function open() {
        closeTimer.stop();
        visible = true;
        isOpen = true;
        search.forceActiveFocus();
        search.text = "";
        appList.currentIndex = 0;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: window.visible = false
    }

    implicitWidth: 400
    implicitHeight: (window.screen ? window.screen.height : (Quickshell.primaryScreen ? Quickshell.primaryScreen.height : 1080)) - 90

    exclusiveZone: -1

    anchors {
        top: true
        left: true
    }

    margins {
        top: 40
        left: 0
    }

    // Only allow clicks inside the visible bounding box
    mask: Region { item: bgRect }

	HyprlandFocusGrab {
		id: focusGrab
		windows: [window]
		active: window.isOpen

		// this fires when you click anywhere outside the launcher window
		onCleared: window.close()
	}

	Rectangle {
        id: bgRect
        width: parent.width
        height: parent.height

	    color: Colors.m3 ? Colors.m3.surface : "#141218"
	    border.color: "transparent"
        border.width: 0
        radius: 25

        // Square corners on the left since it touches the screen edge
        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 25
            color: parent.color
            visible: parent.radius > 0
        }

        // Square corners on the top since it touches the bar
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 25
            color: parent.color
            visible: parent.radius > 0
        }

        // Horizontal slide and fade animation
        opacity: window.isOpen ? 1 : 0
        transform: [
            Translate {
                x: window.isOpen ? 0 : -40
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            }
        ]

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }

		Column {
			anchors.fill: parent
			anchors.margins: 20
			spacing: 16

			SearchInput {
				id: search
				width: parent.width
                colors: Colors
				onUpPressed:   appList.currentIndex = Math.max(0, appList.currentIndex - 1)
				onDownPressed: appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
				onAcceptPressed: appList.launchCurrent()
				onEscapePressed: window.close()
			}
			
			AppList {
				id: appList
				width: parent.width
				height: parent.height - search.height - parent.spacing
				filterText: search.text
                colors: Colors
				onLaunched: window.close()
			}
		}
    }
}
