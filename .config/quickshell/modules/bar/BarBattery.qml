// Battery indicator: compact icon and percentage via UPower service.
import QtQuick
import Quickshell.Services.UPower
import qs.modules
import qs.modules.widgets

Item {
    id: root

    readonly property real pct: UPower.displayDevice?.percentage ?? 1.0
    readonly property int state: UPower.displayDevice?.state ?? UPowerDeviceState.Unknown
    readonly property bool charging: [
        UPowerDeviceState.Charging,
        UPowerDeviceState.FullyCharged,
        UPowerDeviceState.PendingCharge
    ].includes(root.state)

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
