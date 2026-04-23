// DashboardWindow.qml — Main dashboard panel
//
// Material 3 styled panel with three tabs:
//   Overview (calendar + user info + system stats)
//   Media (MPRIS player controls)
//   Wallpapers (carousel + search from wallpaper shell)
//
// Anchored below the clock, closes on focus loss.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "./components"
import "../../qs/services"

PanelWindow {
    id: window

    color: "transparent"
    visible: false

    property bool isOpen: false

    function toggle() {
        if (isOpen) close();
        else open();
    }

    function open() {
        closeTimer.stop();
        visible = true;
        isOpen = true;
    }

    function close() {
        isOpen = false;
        closeTimer.start();
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: window.visible = false
    }

    property int currentTab: 0
    property int previousTab: 0

    // Fixed Wayland Surface maximum size
    implicitWidth: 1100
    implicitHeight: 560

    exclusiveZone: -1

    anchors {
        top: true
        left: true
    }

    margins {
        top: 40
        // Surface is always centered statically
        left: ((window.screen ? window.screen.width : (Quickshell.primaryScreen ? Quickshell.primaryScreen.width : 1920)) - 1100) / 2
    }

    // Only allow clicks inside the visible bounding box
    mask: Region { item: bgRect }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [window]
        active: window.isOpen
        onCleared: window.close()
    }

    Rectangle {
        id: bgRect

        // Center the animated rect inside the static surface
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        // This is what actually animates (internal QML graph, completely tear-free)
        width: window.currentTab === 2 ? 1100 : 480
        height: window.currentTab === 2 ? 310 : 560

        // Drop-down animation
        opacity: window.isOpen ? 1 : 0
        transform: [
            Translate {
                y: window.isOpen ? 0 : -40
                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
            }
        ]

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }

        Behavior on width {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
        Behavior on height {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        color: Colors.m3 ? Colors.m3.surface : "#141218"
        // Rounded at the bottom, square at the top to merge with the bar
        radius: 25

        Rectangle {
            // This rectangle covers the top rounded corners to make them square
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 25
            color: parent.color
            visible: parent.radius > 0
        }

        // Draw left/right/bottom border, skip top since it touches the bar
        border.color: "transparent"
        border.width: 0

        // Prevent children from bleeding outside rounded corners during resize
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            TabBar {
                id: tabBar
                width: 448 // Stays the same size when expanding
                anchors.horizontalCenter: parent.horizontalCenter
                colors: Colors
                currentIndex: window.currentTab
                onTabClicked: (index) => {
                    window.previousTab = window.currentTab;
                    window.currentTab = index;
                }
            }

            Item {
                id: tabContainer
                width: parent.width
                height: parent.height - tabBar.height - parent.spacing
                clip: true

                OverviewTab {
                    width: parent.width
                    height: parent.height
                    colors: Colors
                    x: window.currentTab === 0 ? 0 : -parent.width
                    visible: x > -parent.width && x < parent.width
                    Behavior on x { 
                        enabled: window.currentTab !== 2 && window.previousTab !== 2
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuint } 
                    }
                    onClose: window.close()
                }

                MediaTab {
                    width: parent.width
                    height: parent.height
                    colors: Colors
                    x: window.currentTab === 1 ? 0 : (window.currentTab < 1 ? parent.width : -parent.width)
                    visible: x > -parent.width && x < parent.width
                    Behavior on x { 
                        enabled: window.currentTab !== 2 && window.previousTab !== 2
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuint } 
                    }
                    onClose: window.close()
                }

                WallpaperTab {
                    width: parent.width
                    height: parent.height
                    colors: Colors
                    x: window.currentTab === 2 ? 0 : parent.width
                    visible: x > -parent.width && x < parent.width
                    Behavior on x { 
                        enabled: window.currentTab !== 2 && window.previousTab !== 2
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuint } 
                    }
                    onClose: window.close()
                }
            }
        }
    }
}
