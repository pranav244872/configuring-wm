// Preview / testbench for CpTrackerCard
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.cp_tracker

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#101718"
        implicitWidth: 760
        implicitHeight: 600

        Row {
            id: scene
            anchors.centerIn: parent
            spacing: 24

            CpTrackerCard {
            }
        }

        Timer {
            interval: 1200
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_cp_tracker saved:", r.saveToFile("/tmp/preview_cp_tracker.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
