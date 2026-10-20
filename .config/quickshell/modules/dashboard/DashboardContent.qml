// Dashboard body: a tab row over the control sections, one section per tab.
// Every section stays instantiated (they are light), and each one only does
// work while its own tab is the visible one -- the network list scans, the
// bluetooth list discovers, a background tab is idle.
// Shared with the preview bench.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.dashboard
import qs.modules.bluetooth

Item {
    id: root

    // Sections are reachable by id: the bench injects mocks.
    property alias network: networkSection
    property alias bluetooth: bluetoothSection

    // One source for both the visible labels and the IPC names.
    readonly property var tabLabels: ["NETWORK", "BLUETOOTH", "NOTIFICATIONS"]
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
        root.syncActive();
    }

    function deactivate() {
        root.active = false;
        root.syncActive();
    }

    onCurrentTabChanged: root.syncActive()

    // Only the visible tab does work: the network list scans/rebuilds and the
    // bluetooth list discovers/probes while active. activate() rebuilds each
    // snapshot, so switching back is instantly current.
    function syncActive() {
        if (root.active && root.currentTab === 0)
            networkSection.activate();
        else
            networkSection.deactivate();

        if (root.active && root.currentTab === 1)
            bluetoothSection.activate();
        else
            bluetoothSection.deactivate();
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

            BluetoothSection {
                id: bluetoothSection
            }

            NotificationsSection {
            }
        }
    }
}
