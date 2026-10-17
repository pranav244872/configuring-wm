// Dashboard body: the control sections. Network is the first; bluetooth,
// audio and night light follow in later phases. Shared with the preview bench.
import QtQuick
import qs.modules
import qs.modules.dashboard

Item {
    id: root

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
        anchors.fill: parent
    }
}
