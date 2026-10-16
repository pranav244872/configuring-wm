// Material-style press ripple. Put this inside a parent that clips
// (Rectangle with clip: true), call press(x, y) on press, release() after.
import QtQuick
import qs.modules

Rectangle {
    id: root

    // click point + rest diameter, both set by press()
    property real cx: 0
    property real cy: 0
    property real d: 0

    opacity: 0

    x: root.cx - root.width / 2
    y: root.cy - root.height / 2
    width: root.d
    height: root.d
    radius: root.d / 2

    // Expansion (translate none: the item's centre already sits on the click point)
    NumberAnimation {
        id: grow
        target: root
        property: "scale"
        from: 0.02
        to: 1
        duration: 300
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.animation.curveOut
    }

    // Fade on release while the grow may still be running
    NumberAnimation {
        id: fade
        target: root
        property: "opacity"
        to: 0
        duration: 280
    }

    function press(x, y) {
        root.cx = x;
        root.cy = y;
        if (host) {
            root.d = 2 * Math.max(host.width, host.height);
        }
        root.opacity = 1;
        grow.restart();
    }

    function release() {
        fade.restart();
    }

    // Clipping host (the ripple's parent), used to size the rest diameter
    readonly property Item host: parent
}
