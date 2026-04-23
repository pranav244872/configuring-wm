import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import Quickshell.Wayland
import "../../qs/services"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.namespace: "qs-screenshot-menu"
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    anchors { top: true; bottom: true; left: true; right: true }
    
    color: shouldShow ? Qt.rgba(0, 0, 0, 0.5) : "transparent"
    Behavior on color { ColorAnimation { duration: 250 } }

    visible: shouldShow || menuContainer.y < root.height

    property bool shouldShow: ScreenshotService.showMenu

    MouseArea {
        anchors.fill: parent
        onClicked: ScreenshotService.closeMenu()
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ScreenshotService.closeMenu()
    }

    Item {
        id: menuContainer
        width: 360
        height: 120
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        
        anchors.bottomMargin: root.shouldShow ? 0 : -height
        
        Behavior on anchors.bottomMargin { 
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic } 
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            color: Colors.m3.surface_container_highest
            radius: 16
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                color: parent.color
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            anchors.bottomMargin: 16
            spacing: 12

            ScreenshotBtn {
                iconText: "󰹑"
                label: "Screen"
                onClicked: {
                    ScreenshotService.closeMenu()
                    Quickshell.execDetached(["sh", "-c", "sleep 0.4 && hyprshot -m output"])
                }
            }

            ScreenshotBtn {
                iconText: "󱂬"
                label: "Window"
                onClicked: {
                    ScreenshotService.closeMenu()
                    Quickshell.execDetached(["sh", "-c", "sleep 0.4 && hyprshot -m window"])
                }
            }

            ScreenshotBtn {
                iconText: "󰆞"
                label: "Region"
                onClicked: {
                    ScreenshotService.closeMenu()
                    Quickshell.execDetached(["sh", "-c", "sleep 0.4 && hyprshot -m region"])
                }
            }
        }
    }

    component ScreenshotBtn: Rectangle {
        id: btn
        property string iconText: ""
        property string label: ""
        signal clicked()
        
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 16
        color: btnMa.containsMouse ? Qt.rgba(Colors.m3.on_surface.r, Colors.m3.on_surface.g, Colors.m3.on_surface.b, 0.08) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                text: btn.iconText
                font.family: "Material Design Icons"
                font.pixelSize: 28
                color: Colors.m3.primary
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: btn.label
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Colors.m3.on_surface
                Layout.alignment: Qt.AlignHCenter
            }
        }
        
        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}