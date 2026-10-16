// Bar island: surface + content row. Reused by TopBar on screen and by the
// preview benches, so both render exactly the shipped geometry.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.bar

Item {
    id: root

    property alias activeWsIdOverride: wsIndicator.activeWsIdOverride

    readonly property real bodyWidth: row.implicitWidth + 2 * Theme.bar.pad

    implicitWidth: bodyWidth
    implicitHeight: Theme.bar.height

    BarSurface {
        anchors.fill: parent
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        // Optical centering: the 2px border lives at the bottom edge only,
        // so the visible mass centres 1px above the geometric middle.
        anchors.verticalCenterOffset: -1
        spacing: 10

        BarTray {
            Layout.alignment: Qt.AlignVCenter
        }

        BarClock {
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            color: ColorUtils.transparentize(Theme.colors.outline, 0.4)
        }

        WorkspaceIndicator {
            id: wsIndicator
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            color: ColorUtils.transparentize(Theme.colors.outline, 0.4)
        }

        BarBattery {
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
