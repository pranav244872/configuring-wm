// Launcher body content: search pill + frequency-ranked app list, empty
// state and slim scrollbar. Shared by LauncherWindow and the preview benches.
import QtQuick
import qs.modules
import qs.modules.widgets
import qs.modules.launcher

FocusScope {
    id: root

    signal launch(var app)
    signal dismissed()

    property alias searchText: searchField.text

    property int selectedIndex: 0

    readonly property var filteredApps: AppTracker.getFilteredApps(searchField.text)

    function forceSearchFocus() {
        searchField.forceActiveFocus();
    }

    function clearSearch() {
        searchField.text = "";
        root.selectedIndex = 0;
    }

    function launchSelected() {
        const app = root.filteredApps[root.selectedIndex];
        if (!app)
            return;
        AppTracker.recordLaunch(app.id);
        root.launch(app);
    }

    // Search pill: filled surface, no idle border, primary accent on focus.
    // end-4 proportions: 44 tall, fully rounded.
    Rectangle {
        id: searchBox
        width: root.width
        height: 44
        radius: height / 2
        color: Theme.colors.layer1
        border.width: searchField.activeFocus ? 1 : 0
        border.color: ColorUtils.transparentize(Theme.colors.primary, 0.4)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                font.family: Theme.font.icon
                font.pixelSize: 20
                color: searchField.activeFocus ? Theme.colors.primary : Theme.colors.subtext
            }

            TextInput {
                id: searchField
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 30
                focus: true
                clip: true
                color: Theme.colors.fgLayer0
                font.family: Theme.font.main
                font.pixelSize: Theme.font.size.md
                selectByMouse: true

                StyledText {
                    anchors.fill: parent
                    text: "Search apps..."
                    font: parent.font
                    color: Theme.colors.subtext
                    opacity: 0.6
                    visible: !searchField.text
                }

                onTextChanged: root.selectedIndex = 0

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Up && root.selectedIndex > 0) {
                        root.selectedIndex--;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down && root.selectedIndex < appList.count - 1) {
                        root.selectedIndex++;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected();
                        event.accepted = true;
                    }
                }
            }
        }
    }

    // App list
    ListView {
        id: appList
        x: 0
        y: searchBox.height + 12
        width: root.width
        height: root.height - y
        clip: true
        spacing: 4
        topMargin: 4
        bottomMargin: 12

        model: root.filteredApps

        delegate: LauncherItem {
            required property var modelData
            required property int index

            width: appList.width
            app: modelData
            selected: root.selectedIndex === index

            onActivated: {
                root.selectedIndex = index;
                root.launchSelected();
            }
        }

        // "No apps found" empty state (contrast with the preview row states)
        Column {
            anchors.centerIn: parent
            visible: appList.count === 0 && searchField.text.length > 0
            spacing: 8

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "search_off"
                font.family: Theme.font.icon
                font.pixelSize: 28
                color: Theme.colors.subtext
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No apps found"
                font.pixelSize: Theme.font.size.sm
                color: Theme.colors.subtext
            }
        }

    }
}
