import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    property var menuHandle: null
    property var colors: null

    property real targetX: 0
    property real targetY: 0

    property bool isOpen: false

    onMenuHandleChanged: {
        if (!menuHandle && isOpen) {
            close()
        }
    }

    visible: isOpen || menuContainer.opacity > 0
    color: "transparent"

    WlrLayershell.layer: WlrLayershell.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "qs-tray-menu"

    property var parentScreen: null
    screen: parentScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Dismiss area - closes menu when clicking outside
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.close()
    }

    // Menu container
    Rectangle {
        id: menuContainer

        x: Math.min(Math.max(0, root.targetX - width/2), root.width - width - 10)
        y: root.isOpen ? root.targetY : root.targetY - 10
        opacity: root.isOpen ? 1 : 0
        
        width: 220
        height: stack.implicitHeight + 20

        color: root.colors ? root.colors.m3.surface : "#1e1e2e"
        
        // Round only bottom corners - top corners sharp (attached to bar)
        radius: 0
        bottomLeftRadius: 20
        bottomRightRadius: 20
        topLeftRadius: 0
        topRightRadius: 0
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 12
            shadowColor: "#60000000"
        }

        StackView {
            id: stack
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 10

            implicitWidth: currentItem ? currentItem.implicitWidth : 0
            implicitHeight: currentItem ? currentItem.implicitHeight : 0

            property var rootHandle: root.menuHandle
            property var rootColors: root.colors

            initialItem: TraySubMenu {
                handle: stack.rootHandle
                stackView: stack
                colors: stack.rootColors
            }
        }
        
        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    function open() {
        if (!menuHandle) return
        stack.pop(null)
        isOpen = true
    }

    function close() {
        isOpen = false
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
    }
}