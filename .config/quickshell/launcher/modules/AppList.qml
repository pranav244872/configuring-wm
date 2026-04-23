import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../../qs/services"

ListView {
    id: root

    // Colors service — passed down from parent
    required property var colors

    width: parent.width
    height: parent.height

    clip: true
    spacing: 6
    focus: true

    // Parent gives us the search text via this property
    property string filterText: ""

	signal launched

	// storage for history counts
	property var history: ({})
	readonly property string historyPath: Quickshell.env("HOME") + "/.cache/qs-launcher-history.json"

	FileView {
        id: historyFile
        path: root.historyPath
		blockLoading: true

		onSaved: root.launched()
		onSaveFailed: root.launched()
    }

	// load history when the component is created
	Component.onCompleted: {
        const data = historyFile.text(); //
        if (data && data.trim().length > 0) {
            try {
                history = JSON.parse(data);
            } catch (e) {
                console.log("Error parsing history:", e);
                history = {};
            }
        }
    }

	// sorting logic
	model: DesktopEntries.applications.values
        .filter(entry => entry.name.toLowerCase().includes(filterText.toLowerCase()))
        .sort((a, b) => {
            // Get counts from our history object (default to 0)
            const countA = history[a.id] || 0;
            const countB = history[b.id] || 0;
            
            // Sort by count (descending), then alphabetically if counts are equal
            if (countB !== countA) return countB - countA;
            return a.name.localeCompare(b.name);
        })

	function launchCurrent() {
        const selectedApp = model[currentIndex]
        if (selectedApp) {
            // Create a copy of the object to ensure QML detects the change
            let newHistory = JSON.parse(JSON.stringify(history)); 
            newHistory[selectedApp.id] = (newHistory[selectedApp.id] || 0) + 1;
            history = newHistory; 

            console.log("Launching ID:", selectedApp.id, "New count:", newHistory[selectedApp.id]);

            historyFile.setText(JSON.stringify(history));
            selectedApp.execute();
        }
    }

    delegate: Rectangle {
        width: root.width
        height: 44
        radius: 12

        // Highlight uses secondaryContainer, hover uses surfaceVariant
        color: ListView.isCurrentItem ? colors.m3.secondary_container : (ma.containsMouse ? colors.m3.surface_variant : "transparent")
        border.color: "transparent"
        border.width: 0

        Row {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            IconImage {
                width: 26
                height: 26
                anchors.verticalCenter: parent.verticalCenter
                
                source: Quickshell.iconPath(modelData.icon) || Quickshell.iconPath("application-x-executable")
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.name
                color: ListView.isCurrentItem ? colors.m3.on_secondary_container : colors.m3.on_surface
                font.pixelSize: 14
                font.family: "Inter"
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.currentIndex = index
                root.launchCurrent()
            }
        }
    }
}
