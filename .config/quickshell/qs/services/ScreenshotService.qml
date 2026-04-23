pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property bool showMenu: false

    function toggleMenu() {
        showMenu = !showMenu
    }
    function closeMenu() {
        showMenu = false
    }
}