// Screenshot bench: floating editor window + toolbar with mock strokes and
// texts over a dimmed backdrop, no capture needed. Saves preview_screenshot.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.screenshot

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#ffffff"
        implicitWidth: 960
        implicitHeight: 640

        ScreenshotStore {
            id: mock
        }

        Component.onCompleted: {
            mock.outputW = 920;
            mock.outputH = 520;
            mock.viewX = 120;
            mock.viewY = 90;
            mock.viewW = 520;
            mock.viewH = 300;
            mock.stage = "annotate";
            mock.winW = 520;
            mock.winX = 200;
            mock.winY = 110;
            mock.penColor = "#ffd740";
            mock.strokes = [
                {
                    seq: 1, color: "#ffd740", width: 5,
                    points: [{ x: 60, y: 80 }, { x: 160, y: 120 }, { x: 280, y: 90 }, { x: 370, y: 150 }]
                },
                {
                    seq: 2, color: "#ff5252", width: 3,
                    points: [{ x: 330, y: 220 }, { x: 410, y: 180 }, { x: 490, y: 230 }]
                }
            ];
            mock.texts = [
                { seq: 3, x: 90, y: 30, size: 18, color: "#ffffff", text: "look here" }
            ];
            mock.seq = 3;
        }

        Item {
            id: scene
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.scrim
                opacity: 0.55
            }

            Rectangle {
                x: 20 + mock.viewX
                y: 20 + mock.viewY
                width: mock.viewW
                height: mock.viewH
                color: "transparent"
                border.width: 1
                border.color: ColorUtils.transparentize(Theme.colors.primary, 0.5)
            }

            ScreenshotEditor {
                x: 20 + mock.winX
                y: 20 + mock.winY
                store: mock
            }

            AnnotationToolbar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                store: mock
            }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_screenshot saved:", r.saveToFile("/tmp/opencode/preview_screenshot.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
