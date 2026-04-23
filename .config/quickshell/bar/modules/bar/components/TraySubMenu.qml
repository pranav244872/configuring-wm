import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

ColumnLayout {
    id: root
    
    property var handle: null
    property var stackView: null
    property var colors: null
    
    spacing: 4
    
    QsMenuOpener {
        id: menuOpener
        menu: root.handle
    }
    
    Repeater {
        model: menuOpener.children
        
        delegate: Item {
            id: entryItem
            Layout.fillWidth: true
            Layout.preferredHeight: modelData.isSeparator ? 1 : 36
            visible: true
            
            Rectangle {
                anchors.fill: parent
                color: modelData.isSeparator ? (root.colors ? root.colors.m3.outline_variant : "transparent") : (mouseArea.containsMouse ? (root.colors ? root.colors.m3.surface_variant : "transparent") : "transparent")
                radius: 12
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !modelData.isSeparator && modelData.enabled
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: false
                    
                    onClicked: {
                        if (modelData.hasChildren && stackView) {
                            stackView.push(TraySubMenu, { handle: modelData, stackView: stackView, colors: root.colors })
                        } else {
                            modelData.triggered()
                            root.parent.parent.parent.parent.close() // Close the Popup
                        }
                    }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    visible: !modelData.isSeparator
                    
                    property string iconSource: {
                        let raw = modelData.icon || "";
                        // Fallback checking just in case
                        if (!raw && modelData.iconName) raw = modelData.iconName;
                        if (!raw) return "";
                        if (raw.includes("://")) return raw;
                        if (raw.startsWith("/")) return "file://" + raw;
                        return "image://icon/" + raw;
                    }
                    
                    IconImage {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: parent.iconSource
                        visible: parent.iconSource !== ""
                    }
                    
                    Text {
                        Layout.fillWidth: true
                        text: modelData.text || ""
                        color: modelData.enabled ? (root.colors ? root.colors.m3.on_surface : "white") : (root.colors ? root.colors.m3.outline : "gray")
                        font.family: "Inter"
                        font.pointSize: 10
                        elide: Text.ElideRight
                    }
                    
                    Text {
                        text: "\ue5cc" // chevron_right
                        font.family: "Material Icons Round"
                        color: root.colors ? root.colors.m3.on_surface_variant : "gray"
                        visible: modelData.hasChildren
                    }
                }
            }
        }
    }
    
    // Back button if we're not the root
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        visible: stackView && stackView.depth > 1
        
        Rectangle {
            anchors.fill: parent
            color: backArea.containsMouse ? (root.colors ? root.colors.m3.surface_variant : "gray") : (root.colors ? root.colors.m3.secondary_container : "gray")
            radius: 16
            
            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (stackView) stackView.pop()
                }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                
                Text {
                    text: "\ue5cb" // chevron_left
                    font.family: "Material Icons Round"
                    color: root.colors ? root.colors.m3.on_secondary_container : "white"
                }
                
                Text {
                    Layout.fillWidth: true
                    text: "Back"
                    color: root.colors ? root.colors.m3.on_secondary_container : "white"
                    font.family: "Inter"
                    font.pointSize: 10
                }
            }
        }
    }
}
