import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules
import qs.modules.bar

PanelWindow {
    id: bar

    anchors {
        top: true
    }

    // Keep-awake: while caffeine is on, the bar holds a wayland idle inhibitor
    // (a mapped layer surface counts as visible to the compositor). Our
    // IdleService uses respectInhibitors, so nothing locks/blanks/suspends.
    IdleInhibitor {
        enabled: Caffeine.enabled
        window: bar
    }

    // qs ipc call caffeine <toggle|enable|disable>
    IpcHandler {
        target: "caffeine"

        function toggle(): void { Caffeine.toggle(); }
        function enable(): void { Caffeine.setEnabled(true); }
        function disable(): void { Caffeine.setEnabled(false); }
        function isEnabled(): bool { return Caffeine.enabled; }
    }

    // Push tiled windows down: zone reserves exactly the bar height, so the
    // bar gap always equals gaps_out (30 + 12 - 30 = 12px, same as edges)
    exclusiveZone: 30

    implicitWidth: island.implicitWidth
    implicitHeight: island.implicitHeight
    color: "transparent"

    mask: Region {
        item: island
        intersection: bar.visible ? Intersection.Combine : Intersection.Xor
    }

    BarIsland {
        id: island
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
