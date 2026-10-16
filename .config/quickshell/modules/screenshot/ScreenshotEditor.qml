// Stage 2: floating editor window. Titlebar moves it, the SE grip resizes
// it (aspect locked); the body always shows exactly the captured crop.
import QtQuick
import qs.modules
import qs.modules.widgets
import qs.modules.screenshot

Item {
    id: root

    required property ScreenshotStore store
    signal closeRequested()
    property alias body: body

    // Titlebar drag state
    property real grabX: 0
    property real grabY: 0

    // Resize drag state
    property real resizeStartX: 0
    property real resizeStartW: 0

    readonly property int titleH: 36
    readonly property int statusH: 28
    readonly property int gripSize: 28

    x: root.store.winX
    y: root.store.winY
    width: root.store.winW + 4
    height: root.titleH + root.store.winH + root.statusH + 4

    // Rounded shell chrome: 2px primary border, flat layer surfaces
    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.lg
        color: "transparent"
        border.width: 2
        border.color: Theme.colors.primary
    }

    // Titlebar: flat layer1 with rounded top, drag to move the window
    Rectangle {
        id: title
        x: 2
        y: 2
        width: parent.width - 4
        height: root.titleH
        color: Theme.colors.layer1
        topLeftRadius: Theme.rounding.lg - 2
        topRightRadius: Theme.rounding.lg - 2

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.store.viewW + " × " + root.store.viewH
            font.pixelSize: Theme.font.size.xs
            color: Theme.colors.subtext
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeAllCursor
            onPressed: (event) => {
                root.grabX = event.x;
                root.grabY = event.y;
            }
            onPositionChanged: (event) => {
                if (pressed)
                    root.store.moveWindow(event.x - root.grabX, event.y - root.grabY);
            }
        }

        // Close: glyph centred inside the click box, hover feedback
        MouseArea {
            id: closeMa
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()

            Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                color: parent.containsMouse ? Theme.colors.stateHover : "transparent"
            }

            StyledText {
                anchors.centerIn: parent
                text: Theme.glyphs.shotDiscard
                font.family: Theme.font.icon
                font.pixelSize: 18
                color: Theme.colors.fgLayer0
            }
        }
    }

    // Crop body: the export target (Save/Copy grab exactly this)
    AnnotationStage {
        id: body
        x: 2
        y: 2 + root.titleH
        width: parent.width - 4
        height: root.store.winH
        store: root.store
    }

    // Status bar mirrors the titlebar so the chrome is balanced top/bottom
    Rectangle {
        x: 2
        y: parent.height - 2 - root.statusH
        width: parent.width - 4
        height: root.statusH
        color: Theme.colors.layer1
        bottomLeftRadius: Theme.rounding.lg - 2
        bottomRightRadius: Theme.rounding.lg - 2

        // Divider between the crop and the status bar
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: Theme.colors.outline
        }

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.store.zoom * 100) + "%"
            font.pixelSize: Theme.font.size.xs
            color: Theme.colors.subtext
        }

        StyledText {
            anchors.right: parent.right
            anchors.rightMargin: 36
            anchors.verticalCenter: parent.verticalCenter
            text: "Drag to move · Corner to resize"
            font.pixelSize: Theme.font.size.xs
            color: ColorUtils.transparentize(Theme.colors.subtext, 0.4)
        }
    }

    // SE resize grip, aspect locked (full strength on hover only)
    StyledText {
        x: parent.width - root.gripSize - 2
        y: parent.height - root.gripSize - 2
        width: root.gripSize
        height: root.gripSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Theme.glyphs.shotResize
        font.family: Theme.font.icon
        font.pixelSize: 18
        color: Theme.colors.primary
        opacity: gripMa.containsMouse ? 1 : 0.5

        MouseArea {
            id: gripMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            onPressed: (event) => {
                root.resizeStartX = event.x;
                root.resizeStartW = root.store.winW;
            }
            onPositionChanged: (event) => {
                if (pressed)
                    root.store.resizeWindow(root.resizeStartW + (event.x - root.resizeStartX));
            }
        }
    }
}
