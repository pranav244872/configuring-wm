pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        enabled = !enabled;
    }
}
