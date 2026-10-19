// The wallpaper itself: a background-layer surface, transparent, with an empty
// Region as its mask so every click falls through. A full-screen layer surface
// that accepted input would eat the hot zones and the desktop calendar.
//
// Two slots hold one texture each and the front one is swapped, so a change is
// a plain crossfade: the outgoing image keeps its own source and fades out
// while the incoming fades in. That is also the reason there is no flash of
// desktop between changes -- the old wallpaper is still painted underneath
// until the new one is fully up. (caelestia-shell crossfades the same way in
// background/Wallpaper.qml, but creates and destroys the image objects; two
// fixed slots skip the object churn, and keeping both textures makes picking
// the previous wallpaper back instant.)
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules
import qs.modules.wallpaper

PanelWindow {
    id: host

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    // Ignore, not Auto: Auto positions the surface inside the usable area, so
    // the wallpaper stopped 30px short of the top edge and the strip either
    // side of the bar showed the bare compositor colour. Ignore (-1) spans the
    // whole output and the bar simply draws over it (level `top`).
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
    }

    readonly property string wanted: WallpaperService.current !== ""
                                        ? "file://" + WallpaperService.current : ""

    // Which slot is on top. Swapped only by flip(), never bound, so each slot
    // keeps the source it was last given while it fades out.
    property bool front: false

    // A source is loaded into the hidden slot and waiting to be decoded.
    property bool pending: false

    function show(url) {
        if (url === "")
            return;
        // Load into the hidden slot, then bring it forward *once it is ready*.
        // Flipping immediately fades the old wallpaper out into an empty slot,
        // which shows the bare compositor colour for as long as a 4 MB PNG
        // takes to decode -- measured 2026-10-19, a visible black flash.
        if (host.front)
            slotA.source = url;
        else
            slotB.source = url;
        host.pending = true;
        // Already decoded (picking a wallpaper we have shown before)? Flip now.
        host.flipIfReady();
    }

    function flipIfReady() {
        if (!host.pending)
            return;
        const hidden = host.front ? slotA : slotB;
        if (hidden.status === Image.Ready) {
            host.pending = false;
            host.front = !host.front;
        }
    }

    onWantedChanged: host.show(host.wanted)

    Image {
        id: slotA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(width, height)
        opacity: host.front ? 0 : 1

        onStatusChanged: host.flipIfReady()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveOut
            }
        }
    }

    Image {
        id: slotB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(width, height)
        opacity: host.front ? 1 : 0

        onStatusChanged: host.flipIfReady()

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveOut
            }
        }
    }

    Component.onCompleted: host.show(host.wanted)
}
