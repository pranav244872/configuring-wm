// Stage 1: take the shot. Frozen fullscreen capture under a slurp-style
// dim; region drags and window hovers cut a bright hole through it.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import qs.modules.screenshot

Item {
    id: root

    required property ScreenshotStore store
    signal modePicked(string mode)
    signal captured(real x, real y, real w, real h)

    property real startX: 0
    property real startY: 0
    property real curX: 0
    property real curY: 0
    property bool dragging: false
    property real hoverX: 0
    property real hoverY: 0

    readonly property real selX: Math.min(root.startX, root.curX)
    readonly property real selY: Math.min(root.startY, root.curY)
    readonly property real selW: Math.abs(root.curX - root.startX)
    readonly property real selH: Math.abs(root.curY - root.startY)

    property var hovered: null

    // A close/reopen mid-drag must not leave a stale selection behind
    Connections {
        target: root.store
        function onStageChanged() {
            root.dragging = false;
            root.hovered = null;
        }
    }

    function clampX(x) {
        return Math.max(0, Math.min(root.store.outputW, x));
    }

    function clampY(y) {
        return Math.max(0, Math.min(root.store.outputH, y));
    }

    function clientAt(x, y) {
        for (const c of root.store.clients) {
            if (x >= c.x && y >= c.y && x < c.x + c.w && y < c.y + c.h)
                return c;
        }
        return null;
    }

    // Frozen capture, full output
    Image {
        id: base
        anchors.fill: parent
        source: root.store.imagePath ? "file://" + root.store.imagePath : ""
        fillMode: Image.Stretch
        asynchronous: false
        cache: false
    }

    // slurp-style dim, lifted where the selection sits
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.scrim
        opacity: 0.55
    }

    // Bright interior of the region drag (clipped copy of the capture)
    Item {
        x: root.selX
        y: root.selY
        width: root.selW
        height: root.selH
        clip: true
        visible: root.store.mode === "region" && root.dragging

        Image {
            x: -root.selX
            y: -root.selY
            width: root.store.outputW
            height: root.store.outputH
            source: base.source
            fillMode: Image.Stretch
            asynchronous: false
            cache: false
        }
    }

    Rectangle {
        x: root.selX - 1
        y: root.selY - 1
        width: root.selW + 2
        height: root.selH + 2
        color: "transparent"
        radius: 12
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.mode === "region" && root.dragging
    }

    // Region size label
    Rectangle {
        x: Math.min(root.selX, root.store.outputW - width)
        y: Math.max(0, root.selY - 34)
        implicitWidth: sizeLabel.implicitWidth + 20
        implicitHeight: 26
        radius: 13
        color: Theme.colors.layer1
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.mode === "region" && root.dragging

        StyledText {
            id: sizeLabel
            anchors.centerIn: parent
            text: Math.round(root.selW) + " × " + Math.round(root.selH)
            font.pixelSize: Theme.font.size.xs
        }
    }

    // Window hover: bright frame + title tag
    Rectangle {
        x: (root.hovered?.x ?? 0) - 1
        y: (root.hovered?.y ?? 0) - 1
        width: (root.hovered?.w ?? 0) + 2
        height: (root.hovered?.h ?? 0) + 2
        color: ColorUtils.transparentize(Theme.colors.primary, 0.85)
        radius: 12
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.mode === "window" && root.hovered !== null
    }

    Rectangle {
        x: Math.min(root.hoverX + 16, root.store.outputW - width)
        y: Math.max(0, root.hoverY - 36)
        implicitWidth: Math.min(winLabel.implicitWidth + 20, 320)
        implicitHeight: 26
        radius: 13
        color: Theme.colors.layer1
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.mode === "window" && root.hovered !== null

        StyledText {
            id: winLabel
            anchors.centerIn: parent
            width: parent.width - 20
            text: root.hovered?.title ?? ""
            font.pixelSize: Theme.font.size.xs
            elide: Text.ElideRight
        }
    }

    // Fullscreen frame (no dim over the shot itself)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: Theme.colors.primary
        visible: root.store.mode === "full"
    }

    // Aim lines while dragging (end-4 region selector pattern)
    Rectangle {
        x: 0
        y: Math.round(root.curY)
        width: parent.width
        height: 1
        color: ColorUtils.transparentize(Theme.colors.primary, 0.4)
        visible: root.store.mode === "region" && root.dragging
    }

    Rectangle {
        x: Math.round(root.curX)
        y: 0
        width: 1
        height: parent.height
        color: ColorUtils.transparentize(Theme.colors.primary, 0.4)
        visible: root.store.mode === "region" && root.dragging
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.store.mode === "window"
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton

        onPressed: (event) => {
            if (root.store.mode !== "region")
                return;
            root.startX = root.clampX(event.x);
            root.startY = root.clampY(event.y);
            root.curX = root.startX;
            root.curY = root.startY;
            root.dragging = true;
        }
        onPositionChanged: (event) => {
            if (root.store.mode === "region" && root.dragging) {
                root.curX = root.clampX(event.x);
                root.curY = root.clampY(event.y);
            } else if (root.store.mode === "window") {
                root.hoverX = event.x;
                root.hoverY = event.y;
                root.hovered = root.clientAt(event.x, event.y);
            }
        }
        onReleased: {
            if (root.store.mode === "region" && root.dragging) {
                root.dragging = false;
                if (root.selW >= Theme.screenshot.minSelect && root.selH >= Theme.screenshot.minSelect)
                    root.captured(root.selX, root.selY, root.selW, root.selH);
            }
        }
        onClicked: (event) => {
            if (root.store.mode === "window") {
                const c = root.clientAt(event.x, event.y);
                if (c)
                    root.captured(c.x, c.y, c.w, c.h);
            }
        }
    }

    // Mode picker + shutter, top and bottom centre
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        implicitWidth: modeRow.implicitWidth + 24
        implicitHeight: 48
        radius: 0
        color: Theme.colors.layer1
        border.width: Theme.frame.line
        border.color: Theme.colors.outline

        RowLayout {
            id: modeRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: [
                    { mode: "full", glyph: Theme.glyphs.shotFull },
                    { mode: "region", glyph: Theme.glyphs.shotRegion },
                    { mode: "window", glyph: Theme.glyphs.shotWindow }
                ]

                delegate: Rectangle {
                    required property var modelData

                    implicitWidth: 96
                    implicitHeight: 36
                    radius: 0
                    color: root.store.mode === modelData.mode ? Theme.colors.primary
                        : (modeMa.containsMouse ? Theme.colors.stateHover : "transparent")

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.family: Theme.font.icon
                        font.pixelSize: 20
                        color: root.store.mode === modelData.mode ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
                    }

                    MouseArea {
                        id: modeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modePicked(modelData.mode)
                    }
                }
            }
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        text: root.store.mode === "window" ? "Click a window" : (root.store.mode === "region" ? "Drag a region" : "Fullscreen capture")
        font.pixelSize: Theme.font.size.sm
        color: Theme.colors.fgLayer0
    }

    // Shutter for fullscreen mode (region/window capture on release/click)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        implicitWidth: shutterLabel.implicitWidth + 40
        implicitHeight: 48
        radius: 0
        color: Theme.colors.primary
        visible: root.store.mode === "full"

        StyledText {
            id: shutterLabel
            anchors.centerIn: parent
            text: "Capture"
            font.pixelSize: Theme.font.size.md
            font.weight: Font.DemiBold
            color: Theme.colors.fgPrimary
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.captured(0, 0, root.store.outputW, root.store.outputH)
        }
    }
}
