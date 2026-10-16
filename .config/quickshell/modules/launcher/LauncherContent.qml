// Launcher body: tracked header + rule, square search field,
// frequency-ranked app list, footer rule + hint. Shared by LauncherWindow
// and the preview benches.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import qs.modules.launcher

FocusScope {
    id: root

    signal launch(var app)
    signal dismissed()

    property alias searchText: searchField.text
    property alias searchFocused: searchField.activeFocus

    focus: true

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
        anchors.fill: parent
        spacing: 12

        // Header: tracked label + app count
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MicroLabel {
                text: "APPLICATIONS"
            }

            Item {
                Layout.fillWidth: true
            }

            MicroLabel {
                text: String(root.filteredApps.length).padStart(2, "0")
                color: Theme.colors.primary
            }
        }

        Rule {
        }

        // Search field: square, hairline, accent on focus
        Rectangle {
            id: searchBox
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 0
            color: Theme.colors.layer1
            border.width: Theme.frame.line
            border.color: searchField.activeFocus ? Theme.colors.primary : Theme.colors.outline

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
                        text: "SEARCH ..."
                        font.family: Theme.font.main
                        font.pixelSize: Theme.font.size.md
                        font.letterSpacing: Theme.frame.tracking
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            topMargin: 4
            bottomMargin: 4

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

            // "No apps found" empty state
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
                    text: "NO APPS FOUND"
                    font.pixelSize: Theme.font.size.sm
                    font.letterSpacing: Theme.frame.tracking
                    color: Theme.colors.subtext
                }
            }
        }

        Rule {
        }

        // Footer hint
        MicroLabel {
            Layout.alignment: Qt.AlignHCenter
            text: "ESC // CLOSE"
        }
    }
}
