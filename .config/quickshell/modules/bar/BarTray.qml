// System tray icons, first in the bar (left of the clock). Hidden entirely
// when no icons exist. Left-click activates, right-click opens the app menu.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules
import qs.modules.widgets
import qs.modules.bar

RowLayout {
    id: root

    spacing: 2

    readonly property var liveItems: SystemTray.items.values.filter((i) => i.status !== Status.Passive)

    visible: liveItems.length > 0

    Repeater {
        model: ScriptModel {
            values: root.liveItems
        }

        delegate: Item {
            required property var modelData

            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            Rectangle {
                anchors.fill: parent
                color: trayMa.containsMouse ? Theme.colors.stateHover : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: parent.modelData.icon
            }

            MouseArea {
                id: trayMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: (event) => {
                    const item = parent.modelData;
                    if (event.button === Qt.LeftButton) {
                        if (item.onlyMenu && item.hasMenu)
                            root.openMenuFor(item, trayMa, event.x, event.y);
                        else
                            item.activate();
                    } else if (event.button === Qt.RightButton) {
                        if (item.hasMenu)
                            root.openMenuFor(item, trayMa, event.x, event.y);
                        else
                            item.activate();
                    } else {
                        item.secondaryActivate();
                    }
                }
                onWheel: (event) => {
                    parent.modelData.scroll(event.angleDelta.y > 0 ? 1 : -1, false);
                }
            }
        }
    }

    function openMenuFor(item, ma, clickX, clickY) {
        // mapToGlobal returns window-local coords on layer-shell (the client
        // never learns the compositor-assigned window pos). The bar window is
        // top-centered, so its screen origin is ((screen - window) / 2, 0).
        const ox = (Screen.width - Window.width) / 2;
        const click = ma.mapToGlobal(clickX, clickY);
        const top = ma.mapToGlobal(0, 0);
        const bottom = ma.mapToGlobal(0, ma.height);
        TrayState.openMenu(item.menu, item.title, ox + click.x, top.y, bottom.y + 6);
    }
}
