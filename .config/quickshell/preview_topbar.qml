// A/B bench for the bar flare geometry. Option A = shipped Theme.bar tokens;
// Option B = a slightly thicker flare for comparison by eye.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.modules
import qs.modules.bar

ShellRoot {
    PanelWindow {
        id: win
        visible: true
        color: "#ffffff"
        implicitWidth: 620
        implicitHeight: 220

        Column {
            id: scene
            anchors.centerIn: parent
            spacing: 30

            // Option A: shipped geometry (BarIsland = exact TopBar render)
            BarIsland {
                activeWsIdOverride: 2
            }

            // Option B: thicker flare (32, 18/14)
            Item {
                width: barShape2.width
                height: 32

                Shape {
                    id: barShape2
                    width: rowB.implicitWidth + 20 + 64
                    height: 32
                    layer.enabled: true
                    layer.samples: 4

                    ShapePath {
                        strokeWidth: 0
                        strokeColor: "transparent"
                        fillColor: Theme.colors.layer0
                        startX: 0; startY: 0
                        PathCubic { x: 32; y: 32; control1X: 18; control1Y: 0; control2X: 14; control2Y: 32 }
                        PathLine { x: barShape2.width - 32; y: 32 }
                        PathCubic { x: barShape2.width; y: 0; control1X: barShape2.width - 14; control1Y: 32; control2X: barShape2.width - 18; control2Y: 0 }
                    }

                    ShapePath {
                        strokeWidth: 2
                        strokeColor: Theme.colors.primary
                        fillColor: "transparent"
                        capStyle: ShapePath.FlatCap
                        startX: 0; startY: 0
                        PathCubic { x: 32; y: 31; control1X: 18; control1Y: 0; control2X: 14; control2Y: 31 }
                        PathLine { x: barShape2.width - 32; y: 31 }
                        PathCubic { x: barShape2.width; y: 0; control1X: barShape2.width - 14; control1Y: 31; control2X: barShape2.width - 18; control2Y: 0 }
                    }
                }

                RowLayout {
                    id: rowB
                    anchors.centerIn: parent
                    spacing: 10

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
                        Layout.alignment: Qt.AlignVCenter
                        activeWsIdOverride: 2
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
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene?.grabToImage(function (r) {
                console.log("test_topbar saved:", r.saveToFile("/tmp/opencode/test_topbar.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
