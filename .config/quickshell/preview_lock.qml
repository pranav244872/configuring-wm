// Lock bench: formation card in typing + failed states on dark. The real
// lock surface can't bench (needs a locked session); this covers visuals.
// Saves preview_lock.png and quits.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.lock

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#080808"
        implicitWidth: 980
        implicitHeight: 560

        LockAuth {
            id: authTyping
        }

        LockAuth {
            id: authFailed
        }

        Component.onCompleted: {
            authTyping.buffer = "hunter2";
            authFailed.buffer = "wrong";
            authFailed.state = LockAuth.State.Failed;
        }

        Item {
            id: scene
            anchors.fill: parent

            LockCard {
                x: 40
                y: 60
                width: 408
                height: 430
                auth: authTyping
            }

            LockCard {
                x: 532
                y: 60
                width: 408
                height: 430
                auth: authFailed
            }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_lock saved:", r.saveToFile("/tmp/opencode/preview_lock.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
