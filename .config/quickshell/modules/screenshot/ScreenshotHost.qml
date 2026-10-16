// Screenshot utility: Print captures the current output, then annotate
// (pens + text) in-shell. Save / Copy / Discard are explicit; Print and Esc
// always close immediately, unsaved work is dropped.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.widgets
import qs.modules.screenshot
import qs.modules.bar

PanelWindow {
    id: host

    property bool open: false
    property bool capturing: false
    property bool cancelPending: false
    property string picturesDir: ""
    property string tmpPath: ""

    ScreenshotStore {
        id: store
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: host.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: host.open ? content : null
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", "/tmp/quickshell-screenshot"]);
        // Stale temps (e.g. qs was killed while the overlay was open)
        Quickshell.execDetached(["sh", "-c", "rm -f /tmp/quickshell-screenshot/shot-*.png /tmp/quickshell-screenshot/copy-*.png"]);
        picturesProbe.running = true;
    }

    function show() {
        // Transient popups lose to capture: the tray menu is a later-created
        // overlay that would stay on top of the selector. It holds no state.
        TrayState.closeMenu();
        if (!host.open && !host.capturing)
            host.beginCapture();
    }

    function close() {
        if (host.capturing)
            host.cancelPending = true;
        host.cleanup();
        store.reset();
        host.open = false;
        host.capturing = false;
        host.cancelPending = false;
    }

    function toggleVisible() {
        if (host.open || host.capturing)
            host.close();
        else
            host.show();
    }

    function cleanup() {
        if (host.tmpPath !== "") {
            Quickshell.execDetached(["rm", "-f", host.tmpPath]);
            host.tmpPath = "";
        }
    }

    // ---- capture pipeline: pictures dir -> monitor -> grim -> open --------

    Process {
        id: picturesProbe
        command: ["sh", "-c", "d=$(xdg-user-dir PICTURES 2>/dev/null || true); [ -z \"$d\" ] && d=\"$HOME/Pictures\"; mkdir -p \"$d/Screenshots\"; printf %s \"$d/Screenshots\""]
        stdout: StdioCollector {
            onStreamFinished: host.picturesDir = text.trim()
        }
    }

    Process {
        id: monitorProbe
        stdout: StdioCollector {
            id: monitorOut
            onStreamFinished: host.applyMonitor(monitorOut.text)
        }
    }

    Process {
        id: grimProc
        property bool armed: false
        stdout: StdioCollector {
        }
        onRunningChanged: {
            if (!grimProc.running && grimProc.armed) {
                grimProc.armed = false;
                host.finishCapture();
            }
        }
    }

    Process {
        id: clientsProbe
        stdout: StdioCollector {
            id: clientsOut
            onStreamFinished: host.applyClients(clientsOut.text)
        }
    }

    Process {
        id: copyProc
    }

    function beginCapture() {
        host.capturing = true;
        host.cancelPending = false;
        monitorProbe.command = ["hyprctl", "monitors", "-j"];
        monitorProbe.running = true;
    }

    function applyMonitor(text) {
        let m = null;
        try {
            const ms = JSON.parse(text);
            m = ms.find((x) => x.focused) ?? ms[0];
        } catch (e) {
            m = null;
        }
        if (!m) {
            host.close();
            return;
        }
        store.outputName = m.name;
        store.outputId = m.id;
        store.workspaceId = m.activeWorkspace?.id ?? -1;
        store.outputX = m.x;
        store.outputY = m.y;
        // hyprctl reports physical pixels; overlay coordinates are logical
        const scale = m.scale || 1;
        store.outputW = Math.round(m.width / scale);
        store.outputH = Math.round(m.height / scale);
        host.tmpPath = "/tmp/quickshell-screenshot/shot-" + Date.now() + ".png";
        grimProc.command = ["grim", "-o", m.name, host.tmpPath];
        grimProc.armed = true;
        grimProc.running = true;
    }

    function finishCapture() {
        if (host.cancelPending) {
            host.close();
            return;
        }
        store.imagePath = host.tmpPath;
        store.toCapture();
        host.capturing = false;
        host.open = true;
    }

    // ---- window mode: pickable client rects on this output ----------------

    function refreshClients() {
        clientsProbe.command = ["hyprctl", "clients", "-j"];
        clientsProbe.running = true;
    }

    function applyClients(text) {
        let list = [];
        try {
            const cs = JSON.parse(text);
            for (const c of cs) {
                if (!c.mapped || c.hidden)
                    continue;
                if (c.monitor !== undefined && c.monitor !== store.outputId)
                    continue;
                // hyprshot rule: only the captured output's active workspace
                if (c.workspace && c.workspace.id !== store.workspaceId)
                    continue;
                list.push({
                    x: Math.round(c.at[0] - store.outputX),
                    y: Math.round(c.at[1] - store.outputY),
                    w: Math.round(c.size[0]),
                    h: Math.round(c.size[1]),
                    title: c.title ?? ""
                });
            }
        } catch (e) {
            list = [];
        }
        store.clients = list;
    }

    // ---- modes -------------------------------------------------------------

    function pickMode(mode) {
        store.mode = mode;
        store.toCapture();
        if (mode === "window")
            host.refreshClients();
    }

    function reselect() {
        store.toCapture();
        if (store.mode === "window")
            host.refreshClients();
    }

    function applyCrop(x, y, w, h) {
        store.applyCrop(x, y, w, h);
    }

    // ---- export ------------------------------------------------------------

    function stampName() {
        return "screenshot-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmmss") + ".png";
    }

    function save() {
        editor.body.commitEditor();
        const path = (host.picturesDir || "/tmp") + "/" + host.stampName();
        editor.body.grabToImage(function (r) {
            if (r.saveToFile(path)) {
                store.status = "Saved";
                statusTimer.restart();
            }
        });
    }

    function copy() {
        editor.body.commitEditor();
        const path = "/tmp/quickshell-screenshot/copy-" + Date.now() + ".png";
        editor.body.grabToImage(function (r) {
            if (r.saveToFile(path)) {
                copyProc.command = ["sh", "-c", "wl-copy --type image/png < '" + path + "' && rm -f '" + path + "'"];
                copyProc.running = true;
                store.status = "Copied";
                statusTimer.restart();
            }
        });
    }

    Timer {
        id: statusTimer
        interval: 1400
        onTriggered: store.status = ""
    }

    // ---- overlay -----------------------------------------------------------

    FocusScope {
        id: windowScope
        anchors.fill: parent
        focus: host.open

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Print) {
                host.close();
                event.accepted = true;
            } else if (store.stage === "capture") {
                if (event.key === Qt.Key_F) {
                    host.pickMode("full");
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    host.pickMode("region");
                    event.accepted = true;
                } else if (event.key === Qt.Key_W) {
                    host.pickMode("window");
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && store.mode === "full") {
                    host.applyCrop(0, 0, store.outputW, store.outputH);
                    event.accepted = true;
                }
            } else if (store.stage === "annotate") {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (ctrl && event.key === Qt.Key_Z && !(event.modifiers & Qt.ShiftModifier)) {
                    store.undo();
                    event.accepted = true;
                } else if (ctrl && ((event.key === Qt.Key_Z && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Y)) {
                    store.redo();
                    event.accepted = true;
                } else if (!ctrl && event.key === Qt.Key_B) {
                    store.tool = "pen";
                    event.accepted = true;
                } else if (!ctrl && event.key === Qt.Key_T) {
                    store.tool = "text";
                    event.accepted = true;
                } else if (!ctrl && event.key === Qt.Key_BracketLeft) {
                    store.cycleWidth(-1);
                    event.accepted = true;
                } else if (!ctrl && event.key === Qt.Key_BracketRight) {
                    store.cycleWidth(1);
                    event.accepted = true;
                }
            }
        }

        Item {
            id: content
            anchors.fill: parent
            visible: host.open

            // Dimmed full capture behind the editor: context for the crop
            Image {
                anchors.fill: parent
                source: store.imagePath ? "file://" + store.imagePath : ""
                fillMode: Image.Stretch
                asynchronous: false
                cache: false
                visible: store.stage === "annotate"
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.colors.scrim
                opacity: 0.55
                visible: store.stage === "annotate"
            }

            // Crop origin marker on the backdrop: where the window came from
            Rectangle {
                x: store.viewX
                y: store.viewY
                width: store.viewW
                height: store.viewH
                color: "transparent"
                border.width: 1
                border.color: ColorUtils.transparentize(Theme.colors.primary, 0.5)
                visible: store.stage === "annotate"
            }

            ScreenshotEditor {
                id: editor
                visible: store.stage === "annotate"
                store: store
                onCloseRequested: host.close()
            }

            // Dismiss the width menu on outside click (toolbar stays live)
            MouseArea {
                anchors.fill: parent
                visible: store.stage === "annotate" && store.widthMenuOpen
                onClicked: store.widthMenuOpen = false
            }

            ScreenshotSelector {
                anchors.fill: parent
                visible: store.stage === "capture"
                store: store
                onModePicked: (mode) => host.pickMode(mode)
                onCaptured: (x, y, w, h) => host.applyCrop(x, y, w, h)
            }

            AnnotationToolbar {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                visible: store.stage === "annotate"
                store: store
                onReselectRequested: host.reselect()
                onSaveRequested: host.save()
                onCopyRequested: host.copy()
                onDiscardRequested: host.close()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 92
                text: store.status
                visible: store.status !== ""
            }
        }
    }

    IpcHandler {
        target: "screenshot"

        function toggle(): void {
            host.toggleVisible();
        }

        function open(): void {
            host.show();
        }

        function close(): void {
            host.close();
        }
    }
}
