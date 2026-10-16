// Annotation body: cropped capture + pen canvas + text labels. The capture
// is painted through a bottom-rounded clip so the window keeps the shell's
// rounded chrome. Images use the documented Canvas pattern: loadImage() +
// onImageLoaded + drawImage(url). A checkerboard sits under the image, the
// standard transparency backdrop.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.widgets
import qs.modules.screenshot

Item {
    id: root

    required property ScreenshotStore store
    readonly property real zoom: root.store.zoom
    readonly property real cornerR: 0
    readonly property int checkerSize: 12

    property bool imgReady: false

    clip: true

    function shotUrl() {
        return root.store.imagePath ? "file://" + root.store.imagePath : "";
    }

    function loadShot() {
        const url = root.shotUrl();
        if (url === strokes.imgUrl)
            return;
        if (strokes.imgUrl !== "")
            strokes.unloadImage(strokes.imgUrl);
        strokes.imgUrl = url;
        root.imgReady = false;
        if (url !== "")
            strokes.loadImage(url);
        strokes.requestPaint();
    }

    Component.onCompleted: root.loadShot()

    Connections {
        target: root.store
        function onImagePathChanged() {
            root.loadShot();
        }
    }

    function paintStroke(ctx, points, color, width) {
        if (points.length === 0)
            return;
        ctx.strokeStyle = color;
        ctx.lineWidth = width;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
        ctx.moveTo(points[0].x, points[0].y);
        for (let i = 1; i < points.length; i++)
            ctx.lineTo(points[i].x, points[i].y);
        ctx.stroke();
    }

    function roundBottomPath(ctx, w, h, r) {
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(w, 0);
        ctx.lineTo(w, h - r);
        ctx.arc(w - r, h - r, r, 0, Math.PI / 2);
        ctx.lineTo(r, h);
        ctx.arc(r, h - r, r, Math.PI / 2, Math.PI);
        ctx.closePath();
    }

    function paintCheckers(ctx, w, h) {
        const s = root.checkerSize;
        const cols = Theme.screenshot.checker;
        for (let row = 0, y = 0; y < h; row++, y += s) {
            for (let col = 0, x = 0; x < w; col++, x += s) {
                ctx.fillStyle = ((row + col) % 2 === 0) ? cols[0] : cols[1];
                ctx.fillRect(x, y, s, s);
            }
        }
    }

    Canvas {
        id: strokes
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        property string imgUrl: ""

        onImageLoaded: {
            root.imgReady = true;
            strokes.requestPaint();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(0, 0, width, height);
            if (width < 1 || height < 1 || root.zoom <= 0)
                return;
            if (root.cornerR > 0) {
                root.roundBottomPath(ctx, width, height, Math.min(root.cornerR, width / 2, height / 2));
                ctx.save();
                ctx.clip();
            }
            root.paintCheckers(ctx, width, height);
            // Whole capture scaled so the crop fills the canvas exactly
            if (root.imgReady && strokes.imgUrl !== "" && strokes.isImageLoaded(strokes.imgUrl))
                ctx.drawImage(strokes.imgUrl, -root.store.viewX * root.zoom, -root.store.viewY * root.zoom,
                              root.store.outputW * root.zoom, root.store.outputH * root.zoom);
            ctx.scale(root.zoom, root.zoom);
            for (const s of root.store.strokes)
                root.paintStroke(ctx, s.points, s.color, s.width);
            if (root.cornerR > 0)
                ctx.restore();
        }

        Connections {
            target: root.store
            function onStrokesChanged() {
                strokes.requestPaint();
            }
            function onWinWChanged() {
                strokes.requestPaint();
            }
            function onViewXChanged() {
                strokes.requestPaint();
            }
            function onViewWChanged() {
                strokes.requestPaint();
            }
        }
    }

    // Freehand input + text placement (display coords -> crop coords)
    MouseArea {
        id: drawArea
        anchors.fill: parent
        enabled: root.store.stage === "annotate"
        cursorShape: root.store.tool === "pen" ? Qt.CrossCursor : Qt.IBeamCursor
        acceptedButtons: Qt.LeftButton

        onPressed: (event) => {
            if (root.store.tool === "pen")
                root.store.startStroke(event.x / root.zoom, event.y / root.zoom);
        }
        onPositionChanged: (event) => {
            if (root.store.tool === "pen" && pressed) {
                root.store.addPoint(event.x / root.zoom, event.y / root.zoom);
                strokes.requestPaint();
            }
        }
        onReleased: {
            if (root.store.tool === "pen") {
                root.store.endStroke();
                strokes.requestPaint();
            }
        }
        onClicked: (event) => {
            if (root.store.tool === "text")
                root.placeEditor(event.x, event.y);
            else
                root.store.selectedTextSeq = -1;
        }
    }

    // Committed text labels: transparent, above the draw layer so they can
    // be moved; click selects, the SE grip resizes.
    Repeater {
        model: root.store.texts

        delegate: Item {
            required property var modelData
            required property int index

            readonly property bool selected: modelData.seq === root.store.selectedTextSeq

            property real lastX: 0
            property real lastY: 0
            property real resizeStartX: 0
            property int resizeStartSize: 15

            x: modelData.x * root.zoom
            y: modelData.y * root.zoom
            width: label.width
            height: label.height

            StyledText {
                id: label
                text: parent.modelData.text
                font.pixelSize: parent.modelData.size * root.zoom
                font.weight: Font.DemiBold
                color: parent.modelData.color
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.width: 1
                border.color: ColorUtils.transparentize(Theme.colors.primary, 0.4)
                visible: parent.selected
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeAllCursor
                acceptedButtons: Qt.LeftButton

                onPressed: (event) => {
                    parent.lastX = event.x;
                    parent.lastY = event.y;
                }
                onPositionChanged: (event) => {
                    if (pressed)
                        root.store.moveText(parent.index,
                                            (event.x - parent.lastX) / root.zoom,
                                            (event.y - parent.lastY) / root.zoom);
                    parent.lastX = event.x;
                    parent.lastY = event.y;
                }
                onClicked: root.store.selectedTextSeq = parent.modelData.seq
            }

            Rectangle {
                x: parent.width - 7
                y: parent.height - 7
                width: 14
                height: 14
                radius: 3
                color: Theme.colors.primary
                visible: parent.selected

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeFDiagCursor
                    acceptedButtons: Qt.LeftButton

                    onPressed: (event) => {
                        parent.parent.resizeStartX = event.x;
                        parent.parent.resizeStartSize = parent.parent.modelData.size;
                    }
                    onPositionChanged: (event) => {
                        if (pressed)
                            root.store.resizeText(parent.parent.index,
                                                  parent.parent.resizeStartSize + (event.x - parent.parent.resizeStartX) / root.zoom);
                    }
                }
            }
        }
    }

    // Floating text editor; Enter commits, Esc closes the utility (host).
    TextInput {
        id: editor
        visible: false
        color: root.store.penColor
        font.family: Theme.font.main
        font.weight: Font.DemiBold
        selectByMouse: true

        function openAt(x, y) {
            editor.x = x;
            editor.y = y;
            editor.text = "";
            editor.font.pixelSize = root.store.textSize * root.zoom;
            editor.color = root.store.penColor;
            editor.visible = true;
            editor.forceActiveFocus();
        }

        function commit() {
            if (editor.visible) {
                root.store.addText(editor.x / root.zoom, editor.y / root.zoom, editor.text);
                let best = -1;
                for (const t of root.store.texts) {
                    if (t.seq > best)
                        best = t.seq;
                }
                root.store.selectedTextSeq = best;
                editor.visible = false;
                editor.text = "";
            }
        }

        onAccepted: editor.commit()
        onActiveFocusChanged: {
            if (!editor.activeFocus)
                editor.commit();
        }
    }

    function placeEditor(x, y) {
        editor.commit();
        editor.openAt(x, y);
    }

    function commitEditor() {
        editor.commit();
    }
}
