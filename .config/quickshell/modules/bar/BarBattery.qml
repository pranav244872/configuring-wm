// Battery indicator: compact icon and percentage from the shared battery watch
// (which also owns the low-battery warnings -- see modules/power/BatteryWatch).
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules
import qs.modules.power
import qs.modules.widgets

Item {
    id: root

    readonly property real pct: BatteryWatch.pct
    readonly property int state: BatteryWatch.state
    readonly property bool charging: BatteryWatch.charging

    // Shell-level IPC lives here because the bar is the always-present owner of
    // the reading (same shape as `qs ipc call wallpaper …`).
    IpcHandler {
        target: "battery"

        function status(): string {
            const mode = BatteryWatch.charging ? "charging"
                       : BatteryWatch.discharging ? "discharging" : "idle";
            return mode + " " + BatteryWatch.level + "%"
                + (BatteryWatch.warnedCritical ? " critical-sent"
                   : BatteryWatch.warnedLow ? " low-sent" : "");
        }

        function check(): void {
            BatteryWatch.check();
        }

        // Manual trigger, the analogue of `omarchy-battery-low <level>`.
        function warn(level: int): void {
            BatteryWatch.warn(level);
        }
    }

    readonly property color fgColor: {
        if (root.charging)
            return Theme.colors.primary;
        if (root.pct <= 0.15)
            return Theme.colors.error;
        if (root.pct <= 0.30)
            return Theme.colors.warning;
        return Theme.colors.fgLayer1;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.battery(root.pct, root.charging)
            color: root.fgColor
            font.pixelSize: 16
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.pct * 100) + "%"
            color: root.fgColor
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: 1
        }
    }
}
