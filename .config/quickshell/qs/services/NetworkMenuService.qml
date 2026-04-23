pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    property bool showMenu: false
    property string activeTab: "wifi"

    function open(tab) {
        activeTab = tab
        showMenu = true
    }
    
    function close() {
        showMenu = false
    }
}