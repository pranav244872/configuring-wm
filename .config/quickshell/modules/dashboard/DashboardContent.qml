// Dashboard body: a tab row over the control sections, one section per tab.
// Both sections stay instantiated (they are light), and the network list only
// scans while its own tab is the visible one, so a background tab does no work.
// Shared with the preview bench.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.dashboard

Item {
    id: root

    // Sections are reachable by id: the bench injects mocks.
    property alias network: networkSection

    // One source for both the visible labels and the IPC names.
    readonly property var tabLabels: ["NETWORK", "NOTIFICATIONS"]
    readonly property var tabNames: root.tabLabels.map(label => label.toLowerCase())

    property int currentTab: 0

    // Sheet visibility, driven by the host.
    property bool active: false

    function tabName() {
        return root.tabNames[root.currentTab] ?? "";
    }

    function setTab(index) {
        root.currentTab = Math.max(0, Math.min(root.tabLabels.length - 1, index));
    }

    function stepTab(delta) {
        root.setTab(root.currentTab + delta);
    }

    function setTabByName(name) {
        const index = root.tabNames.indexOf(String(name).toLowerCase());
        if (index >= 0)
            root.setTab(index);
    }

    function activate() {
        root.active = true;
        root.syncScanning();
    }

    function deactivate() {
        root.active = false;
        root.syncScanning();
    }

    onCurrentTabChanged: root.syncScanning()

    // The list scans only while the sheet is open AND the network tab is the
    // visible one. activate() rebuilds the snapshot and starts the scan, so
    // switching back to the tab is instantly current.
    function syncScanning() {
        if (root.active && root.currentTab === 0)
            networkSection.activate();
        else
            networkSection.deactivate();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        DashboardTabs {
            Layout.fillWidth: true
            labels: root.tabLabels
            currentIndex: root.currentTab
            onSelected: (index) => root.setTab(index)
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            NetworkSection {
                id: networkSection
            }

            NotificationsSection {
            }
        }
    }
}
