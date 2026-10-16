// Calendar bench: the desktop widget on a dark backdrop, plus a shifted
// month to check filler dimming. Saves preview_calendar.png and quits.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.calendar

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#101718"
        implicitWidth: 760
        implicitHeight: 520

        Row {
            id: scene
            anchors.centerIn: parent
            spacing: 24

            CalendarCard {
            }
        }

        Timer {
            interval: 600
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_calendar saved:", r.saveToFile("/tmp/opencode/preview_calendar.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
