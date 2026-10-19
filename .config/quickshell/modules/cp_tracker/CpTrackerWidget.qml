// ~/.config/quickshell/modules/cp_tracker/CpTrackerWidget.qml
// Desktop CP Tracker window: fullscreen background surface, draggable card.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.cp_tracker

PanelWindow {
    id: host

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool posLoaded: false

    Item {
        id: grabAll
        anchors.fill: parent
    }

    mask: Region {
        item: card.dragging ? grabAll : card
    }

    Component.onCompleted: posProbe.running = true

    Process {
        id: posProbe
        command: ["sh", "-c", "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/cp_widget_pos.json\" 2>/dev/null || echo {}"]
        stdout: StdioCollector {
            id: posOut
            onStreamFinished: host.applyPos(posOut.text)
        }
    }

    function applyPos(text) {
        const sw = host.screen?.width ?? 1920;
        const sh = host.screen?.height ?? 1080;
        card.boundW = sw;
        card.boundH = sh;
        try {
            const p = JSON.parse(text);
            if (typeof p.x === "number" && typeof p.y === "number") {
                card.x = Math.max(0, Math.min(sw - card.width, Math.round(p.x)));
                card.y = Math.max(0, Math.min(sh - card.height, Math.round(p.y)));
                host.posLoaded = true;
                return;
            }
        } catch (e) {
        }
        // Default position: left of the calendar widget
        card.x = Math.max(20, sw - (card.width * 2) - 40);
        card.y = 44;
        host.posLoaded = true;
    }

    property real lastSavedX: -1
    property real lastSavedY: -1

    function savePos() {
        if (Math.abs(card.x - host.lastSavedX) < 1 && Math.abs(card.y - host.lastSavedY) < 1)
            return;
        host.lastSavedX = card.x;
        host.lastSavedY = card.y;
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell\" && printf '{\"x\":%d,\"y\":%d}' '" + Math.round(card.x) + "' '" + Math.round(card.y) + "' > \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/cp_widget_pos.json\""]);
    }

    CpTrackerCard {
        id: card
        width: 320
        height: card.implicitHeight
        visible: host.posLoaded

        onDragFinished: host.savePos()
    }
}
