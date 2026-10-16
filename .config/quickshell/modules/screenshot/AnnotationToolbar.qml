// Bottom-centre toolbar: mode, tool, pens, actions. One pill, no scrolling.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import qs.modules.screenshot

Rectangle {
    id: root

    required property ScreenshotStore store
    signal reselectRequested()
    signal saveRequested()
    signal copyRequested()
    signal discardRequested()

    implicitWidth: row.implicitWidth + 32
    implicitHeight: Theme.screenshot.toolbarHeight
    radius: height / 2
    color: Theme.colors.layer1
    border.width: 2
    border.color: Theme.colors.primary

    component ToolButton: Rectangle {
        id: btn
        required property string glyph
        property bool active: false
        signal pressed()

        implicitWidth: Theme.screenshot.toolSize
        implicitHeight: Theme.screenshot.toolSize
        radius: height / 2
        color: btn.active ? Theme.colors.primaryContainer
            : (btnMa.containsMouse ? Theme.colors.stateHover : "transparent")

        StyledText {
            anchors.centerIn: parent
            text: btn.glyph
            font.family: Theme.font.icon
            font.pixelSize: 20
            color: btn.active ? Theme.colors.fgPrimaryContainer : Theme.colors.fgLayer0
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.pressed()
        }
    }

    component Divider: Rectangle {
        implicitWidth: 1
        implicitHeight: 24
        color: Theme.colors.outline
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        ToolButton {
            glyph: Theme.glyphs.shotReselect
            onPressed: root.reselectRequested()
        }

        Divider {}

        ToolButton {
            glyph: Theme.glyphs.shotPen
            active: root.store.tool === "pen"
            onPressed: root.store.tool = "pen"
        }
        ToolButton {
            glyph: Theme.glyphs.shotText
            active: root.store.tool === "text"
            onPressed: root.store.tool = "text"
        }

        // Pen colour swatches
        Repeater {
            model: Theme.screenshot.penColors

            delegate: Rectangle {
                required property var modelData
                required property int index

                implicitWidth: Theme.screenshot.swatchSize
                implicitHeight: Theme.screenshot.swatchSize
                radius: height / 2
                color: modelData
                border.width: root.store.penColor == modelData ? 2 : 1
                border.color: root.store.penColor == modelData ? Theme.colors.primary : Theme.colors.outline

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.penColor = parent.modelData
                }
            }
        }

        // Pen width opens a size menu with true-width previews
        ToolButton {
            id: widthBtn
            glyph: Theme.glyphs.shotWidth
            active: root.store.widthMenuOpen
            onPressed: root.store.widthMenuOpen = !root.store.widthMenuOpen
        }

        Divider {}

        ToolButton {
            glyph: Theme.glyphs.shotUndo
            onPressed: root.store.undo()
        }
        ToolButton {
            glyph: Theme.glyphs.shotRedo
            onPressed: root.store.redo()
        }
        ToolButton {
            glyph: Theme.glyphs.shotClear
            onPressed: root.store.clearAll()
        }

        Divider {}

        ToolButton {
            glyph: Theme.glyphs.shotSave
            onPressed: root.saveRequested()
        }
        ToolButton {
            glyph: Theme.glyphs.shotCopy
            onPressed: root.copyRequested()
        }
        ToolButton {
            glyph: Theme.glyphs.shotDiscard
            onPressed: root.discardRequested()
        }
    }

    // Size menu: true-width line previews in the current pen colour
    Rectangle {
        id: widthMenu
        width: 190
        height: widthCol.implicitHeight + 16
        radius: 12
        color: Theme.colors.layer1
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.widthMenuOpen

        Column {
            id: widthCol
            anchors.centerIn: parent
            spacing: 2

            // Live width slider, 1..12px
            Item {
                implicitWidth: 174
                height: 34

                readonly property real travel: 110 - 12
                readonly property real ratio: (root.store.penWidth - 1) / 11
                function widthFromX(x) {
                    return Math.max(1, Math.min(12, Math.round(1 + Math.max(0, Math.min(1, (x - 16 - 6) / travel)) * 11)));
                }

                Rectangle {
                    x: 16
                    y: parent.height / 2 - 2
                    width: 110
                    height: 4
                    radius: 2
                    color: Theme.colors.barTrack
                }

                Rectangle {
                    x: 16
                    y: parent.height / 2 - 2
                    width: parent.ratio * 110
                    height: 4
                    radius: 2
                    color: Theme.colors.primary
                }

                Rectangle {
                    x: 16 + parent.ratio * 110 - 6
                    y: parent.height / 2 - 6
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.colors.primary
                }

                StyledText {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.store.penWidth + "px"
                    font.pixelSize: Theme.font.size.xs
                    color: Theme.colors.subtext
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (event) => root.store.penWidth = parent.widthFromX(event.x)
                    onPositionChanged: (event) => {
                        if (pressed)
                            root.store.penWidth = parent.widthFromX(event.x);
                    }
                }
            }

            Repeater {
                model: Theme.screenshot.penWidths

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    implicitWidth: 174
                    implicitHeight: 38
                    radius: 8
                    color: root.store.penWidth === modelData ? Theme.colors.primaryContainer
                        : (sizeMa.containsMouse ? Theme.colors.stateHover : "transparent")

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 96
                        height: parent.modelData
                        radius: parent.modelData / 2
                        color: root.store.penColor
                    }

                    StyledText {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: ["Fine", "Medium", "Bold"][parent.index] ?? ""
                        font.pixelSize: Theme.font.size.xs
                        color: root.store.penWidth === parent.modelData ? Theme.colors.fgPrimaryContainer : Theme.colors.fgLayer0
                    }

                    MouseArea {
                        id: sizeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.store.penWidth = parent.modelData;
                            root.store.widthMenuOpen = false;
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root.store
        function onWidthMenuOpenChanged() {
            if (root.store.widthMenuOpen)
                root.placeMenu();
        }
    }

    function placeMenu() {
        const p = widthBtn.mapToItem(root, 0, 0);
        widthMenu.x = Math.max(8, Math.min(root.width - widthMenu.width - 8,
                                          p.x + widthBtn.width / 2 - widthMenu.width / 2));
        widthMenu.y = p.y - widthMenu.height - 10;
    }
}
