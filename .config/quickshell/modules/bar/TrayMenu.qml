// Tray app context menu: square panel, square rows, full submenu stack.
// Driven by QsMenuOpener over the DBus menu handle (Caelestia pattern).
import QtQuick
import Quickshell
import Quickshell.Widgets
import QtQuick.Controls
import qs.modules
import qs.modules.widgets
import qs.modules.bar

StackView {
    id: root

    required property var handle
    required property string appTitle
    signal dismissed()

    implicitWidth: 230
    implicitHeight: (currentItem as SubMenu)?.hasChildren ? currentItem.implicitHeight + 16 : 44

    initialItem: SubMenu {
        handle: root.handle
        title: root.appTitle
    }

    Component {
        id: subMenuComp

        SubMenu {}
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }
    pushEnter: NoAnim {
    }
    pushExit: NoAnim {
    }
    popEnter: NoAnim {
    }
    popExit: NoAnim {
    }

    component SubMenu: Column {
        id: menu

        required property var handle
        property string title: ""
        property bool isSubMenu: false
        readonly property bool hasChildren: menuOpener.children.values.some((e) => !e.isSeparator)

        // Leading/trailing separators never render (Electron apps append
        // trailing ones), nor do text-less rows: strip them from the model.
        readonly property var cleanChildren: {
            const vs = menuOpener.children.values.filter((e) => e.isSeparator || (e.text || "") !== "").slice();
            while (vs.length > 0 && vs[0].isSeparator)
                vs.shift();
            while (vs.length > 0 && vs[vs.length - 1].isSeparator)
                vs.pop();
            return vs;
        }

        padding: 8
        spacing: 2

        QsMenuOpener {
            id: menuOpener
            menu: menu.handle
        }

        StyledText {
            width: parent.width - 16
            // Column still slots hidden items, so collapse their height too
            height: visible ? implicitHeight : 0
            text: menu.title.toUpperCase()
            font.pixelSize: Theme.frame.labelSize
            font.letterSpacing: Theme.frame.tracking
            color: Theme.colors.subtext
            elide: Text.ElideRight
            visible: !menu.isSubMenu && menu.title !== ""
        }

        Rectangle {
            width: parent.width - 16
            height: visible ? Theme.frame.line : 0
            color: Theme.colors.outline
            visible: !menu.isSubMenu && menu.title !== ""
        }

        Repeater {
            model: menu.cleanChildren

            delegate: Rectangle {
                required property var modelData

                implicitWidth: 214
                implicitHeight: modelData.isSeparator ? 9 : 34
                color: "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: Theme.colors.outline
                    visible: parent.modelData.isSeparator
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10
                    visible: !parent.modelData.isSeparator

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: parent.parent.modelData.icon
                        visible: parent.parent.modelData.icon !== ""
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (parent.children[0].visible ? 26 : 0) - (expand.visible ? 26 : 0)
                        text: parent.parent.modelData.text
                        font.pixelSize: Theme.font.size.sm
                        color: parent.parent.modelData.enabled ? Theme.colors.fgLayer0 : Theme.colors.subtext
                        elide: Text.ElideRight
                    }

                    StyledText {
                        id: expand
                        anchors.verticalCenter: parent.verticalCenter
                        text: "chevron_right"
                        font.family: Theme.font.icon
                        font.pixelSize: 18
                        color: Theme.colors.subtext
                        visible: parent.parent.modelData.hasChildren
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: parent.modelData.enabled ? Theme.colors.stateHover : "transparent"
                    visible: rowMa.containsMouse && !parent.modelData.isSeparator
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: parent.modelData.enabled && !parent.modelData.isSeparator
                    onClicked: {
                        const entry = parent.modelData;
                        if (entry.hasChildren)
                            root.push(subMenuComp.createObject(null, {
                                handle: entry,
                                isSubMenu: true,
                                title: entry.text
                            }));
                        else {
                            entry.triggered();
                            root.dismissed();
                        }
                    }
                }
            }
        }

        // Back row for submenus
        Rectangle {
            implicitWidth: 214
            implicitHeight: menu.isSubMenu ? 34 : 0
            color: backMa.containsMouse ? Theme.colors.stateHover : "transparent"
            visible: menu.isSubMenu

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                spacing: 6

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_left"
                    font.family: Theme.font.icon
                    font.pixelSize: 18
                    color: Theme.colors.primary
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "BACK"
                    font.pixelSize: Theme.font.size.xs
                    font.letterSpacing: Theme.frame.tracking
                    color: Theme.colors.primary
                }
            }

            MouseArea {
                id: backMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pop()
            }
        }
    }
}
