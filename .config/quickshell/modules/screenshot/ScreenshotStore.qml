// Screenshot working state: crop view, annotations, tool selection.
import QtQuick
import qs.modules

QtObject {
    id: root

    property string mode: "region"    // full | region | window
    property string stage: "idle"     // idle | capture | select | annotate

    property string imagePath: ""
    property string outputName: ""
    property int outputId: -1
    property int workspaceId: -1      // active workspace of the captured output
    property int outputX: 0
    property int outputY: 0
    property int outputW: 0
    property int outputH: 0

    // Crop view in overlay coordinates (fixed once captured)
    property int viewX: 0
    property int viewY: 0
    property int viewW: 0
    property int viewH: 0

    // Floating editor window (display coordinates, aspect follows the crop).
    // Chrome: 2px frame + 36px titlebar + 28px status bar.
    readonly property int chromeH: 68
    property int winX: 0
    property int winY: 0
    property int winW: 0
    readonly property int winH: root.winW * root.viewH / Math.max(1, root.viewW)
    readonly property real zoom: root.winW / Math.max(1, root.viewW)

    property var clients: []          // {x, y, w, h, title}
    property var strokes: []          // {seq, color, width, points: [{x, y}]}
    property var texts: []            // {seq, x, y, size, color, text}
    property var redoStack: []        // {kind: "stroke"|"text", item}
    property int seq: 0
    property int selectedTextSeq: -1

    property string tool: "pen"       // pen | text
    property color penColor: Theme.screenshot.penColors[0]
    property int penWidth: Theme.screenshot.penWidths[1]
    property bool widthMenuOpen: false
    property int textSize: Theme.font.size.md
    property string status: ""

    function resetAnnotations() {
        root.strokes = [];
        root.texts = [];
        root.redoStack = [];
        root.selectedTextSeq = -1;
    }

    function fullView() {
        root.viewX = 0;
        root.viewY = 0;
        root.viewW = root.outputW;
        root.viewH = root.outputH;
    }

    function toCapture() {
        root.fullView();
        root.resetAnnotations();
        root.widthMenuOpen = false;
        root.stage = "capture";
    }

    function applyCrop(x, y, w, h) {
        // Clamp to the output: an overshooting drag would otherwise store a
        // negative/overflowing rect, which renders as a gap strip in the crop.
        x = Math.max(0, Math.min(root.outputW - 1, Math.round(x)));
        y = Math.max(0, Math.min(root.outputH - 1, Math.round(y)));
        w = Math.max(1, Math.min(root.outputW - x, Math.round(w)));
        h = Math.max(1, Math.min(root.outputH - y, Math.round(h)));
        root.viewX = x;
        root.viewY = y;
        root.viewW = w;
        root.viewH = h;
        root.resetAnnotations();
        root.centerWindow();
        root.stage = "annotate";
    }

    // Editor window starts at the crop size (capped to fit), centred
    function centerWindow() {
        const fit = Math.min(1, root.outputW / Math.max(1, root.viewW),
                                (root.outputH - 120) / Math.max(1, root.viewH));
        root.winW = Math.max(240, Math.round(root.viewW * fit));
        root.winX = Math.round((root.outputW - root.winW) / 2);
        root.winY = Math.round((root.outputH - root.winH - root.chromeH) / 2);
    }

    function moveWindow(dx, dy) {
        root.winX = Math.max(0, Math.min(root.outputW - root.winW, root.winX + dx));
        root.winY = Math.max(0, Math.min(root.outputH - root.winH - root.chromeH, root.winY + dy));
    }

    function resizeWindow(newW) {
        const aspect = root.viewH / Math.max(1, root.viewW);
        const maxW = Math.min(root.outputW, (root.outputH - root.chromeH) / Math.max(0.01, aspect));
        root.winW = Math.max(240, Math.min(Math.round(maxW), Math.round(newW)));
        root.winX = Math.max(0, Math.min(root.outputW - root.winW, root.winX));
        root.winY = Math.max(0, Math.min(root.outputH - root.winH - root.chromeH, root.winY));
    }

    function startStroke(x, y) {
        root.seq++;
        root.redoStack = [];
        root.strokes = root.strokes.concat([{
            seq: root.seq,
            color: root.penColor,
            width: root.penWidth,
            points: [{ x: x, y: y }]
        }]);
    }

    function addPoint(x, y) {
        if (root.strokes.length === 0)
            return;
        const s = root.strokes[root.strokes.length - 1];
        s.points = s.points.concat([{ x: x, y: y }]);
        root.strokesChanged();
    }

    function endStroke() {
        if (root.strokes.length === 0)
            return;
        const s = root.strokes[root.strokes.length - 1];
        if (s.points.length < 2)
            root.strokes = root.strokes.slice(0, -1);
    }

    function addText(x, y, text) {
        if (!text || text.length === 0)
            return;
        root.seq++;
        root.redoStack = [];
        root.texts = root.texts.concat([{
            seq: root.seq,
            x: x,
            y: y,
            size: root.textSize,
            color: root.penColor,
            text: text
        }]);
    }

    function moveText(i, dx, dy) {
        if (i < 0 || i >= root.texts.length)
            return;
        // No rounding here: at high zoom a mousemove is a fraction of a crop
        // pixel, and rounding every event eats the movement.
        const t = root.texts[i];
        t.x = t.x + dx;
        t.y = t.y + dy;
        root.textsChanged();
    }

    function resizeText(i, size) {
        if (i < 0 || i >= root.texts.length)
            return;
        root.texts[i].size = Math.max(8, Math.min(72, size));
        root.textsChanged();
    }

    function selectedIndex() {
        for (let i = 0; i < root.texts.length; i++) {
            if (root.texts[i].seq === root.selectedTextSeq)
                return i;
        }
        return -1;
    }

    function cycleWidth(dir) {
        const ws = Theme.screenshot.penWidths;
        const i = Math.max(0, ws.indexOf(root.penWidth));
        root.penWidth = ws[Math.max(0, Math.min(ws.length - 1, i + dir))];
    }

    function undo() {
        const s = root.strokes[root.strokes.length - 1];
        const t = root.texts[root.texts.length - 1];
        if (!s && !t)
            return;
        if (t && (!s || t.seq > s.seq)) {
            root.texts = root.texts.slice(0, -1);
            root.redoStack = root.redoStack.concat([{ kind: "text", item: t }]);
        } else {
            root.strokes = root.strokes.slice(0, -1);
            root.redoStack = root.redoStack.concat([{ kind: "stroke", item: s }]);
        }
    }

    function redo() {
        if (root.redoStack.length === 0)
            return;
        const r = root.redoStack[root.redoStack.length - 1];
        root.redoStack = root.redoStack.slice(0, -1);
        if (r.kind === "text")
            root.texts = root.texts.concat([r.item]);
        else
            root.strokes = root.strokes.concat([r.item]);
    }

    function clearAll() {
        root.resetAnnotations();
    }

    function reset() {
        root.mode = "region";
        root.stage = "idle";
        root.imagePath = "";
        root.outputName = "";
        root.workspaceId = -1;
        root.clients = [];
        root.resetAnnotations();
        root.tool = "pen";
        root.status = "";
    }
}
