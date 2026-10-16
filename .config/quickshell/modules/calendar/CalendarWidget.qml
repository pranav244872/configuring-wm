// Desktop month calendar window: fullscreen background surface (windows
// cover it, wallpaper shows through), the card floats where you drag it.
// Click-through everywhere except the card; position persists in cache.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.calendar

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

    // Fullscreen input catcher: the click mask widens to this while a drag
    // runs, so reshaping the card's own region mid-gesture can't stutter it
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
        command: ["sh", "-c", "cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/calendar_pos.json\" 2>/dev/null || echo {}"]
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
        card.x = sw - card.width - 20;
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
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell\" && printf '{\"x\":%d,\"y\":%d}' '" + Math.round(card.x) + "' '" + Math.round(card.y) + "' > \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/calendar_pos.json\""]);
    }

    CalendarCard {
        id: card
        width: 320
        height: card.implicitHeight
        visible: host.posLoaded

        onDragFinished: host.savePos()
    }
}
