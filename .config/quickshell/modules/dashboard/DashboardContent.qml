// Dashboard body: the control sections, side by side. Network is the first;
// bluetooth, audio and night light follow in later phases. Shared with the
// preview bench.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.dashboard

RowLayout {
    id: root

    spacing: 24

    // Sections are reachable by id: the bench injects mocks, the host drives
    // activate/deactivate.
    property alias network: networkSection

    // Sections that need to know when the sheet is visible (the network list
    // only scans while open).
    function activate() {
        networkSection.activate();
    }

    function deactivate() {
        networkSection.deactivate();
    }

    NetworkSection {
        id: networkSection
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    NotificationsSection {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
}
