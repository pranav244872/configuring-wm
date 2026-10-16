// Tray menu state: which app menu is open and where it anchors. BarTray
// writes it, TrayMenuHost renders it. Singleton so the two trees can share.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property var handle: null
    property string appTitle: ""
    property real anchorX: 0
    property real anchorY: 0
    property bool open: false

    function openMenu(menuHandle, title, x, y) {
        root.handle = menuHandle;
        root.appTitle = title ?? "";
        root.anchorX = x;
        root.anchorY = y;
        root.open = true;
    }

    function closeMenu() {
        root.open = false;
        root.handle = null;
    }
}
