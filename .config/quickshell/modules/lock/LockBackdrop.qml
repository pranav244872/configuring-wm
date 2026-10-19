// Lock backdrop: the current wallpaper, blurred under a scrim. Shared by the
// lock surface and the lock bench so the two can never drift (the same reason
// WallpaperSurface is shared with its bench).
//
// The lock has to draw the wallpaper itself: the compositor hides every other
// surface while the session is locked, so the background-layer
// WallpaperBackground is not on screen here (verified 2026-10-19 -- with the
// surface transparent the locked screen is black, not the desktop).
// caelestia's lock paints its wallpaper the same way; DMS matches, both with a
// blur behind a scrim.
import QtQuick
import QtQuick.Effects
import qs.modules
import qs.modules.wallpaper

Item {
    id: root

    // A session with no wallpaper still gets the formation's flat floor.
    Rectangle {
        anchors.fill: parent
        color: Theme.lock.backdrop
    }

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        // The same decode size as WallpaperBackground, so locking re-uses the
        // pixmap the desktop already decoded (a 1080p PNG costs 142-308 ms).
        sourceSize: Qt.size(width, height)
        source: WallpaperService.current !== "" ? "file://" + WallpaperService.current : ""

        // Fade the wallpaper in rather than popping it over the flat floor.
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveOut
            }
        }

        layer.enabled: true

        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: Theme.lock.blur
            blurMax: Theme.lock.blurMax
            blurMultiplier: 1
        }
    }

    // Scrim: keeps the card legible over a bright wallpaper.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: Theme.lock.scrimAlpha
    }
}
