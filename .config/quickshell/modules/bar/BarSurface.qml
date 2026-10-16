// Bar body: body curves into the top screen edge via the shared flare block
// (Theme.bar), plus the 2px primary border on exposed edges. Drawn by TopBar
// and the preview benches so the geometry lives in exactly one place.
import QtQuick
import QtQuick.Shapes
import qs.modules

Shape {
    id: root

    layer.enabled: true
    layer.samples: 4

    implicitHeight: Theme.bar.height

    readonly property real w: root.width
    readonly property real h: root.height
    readonly property real f: Theme.bar.flare
    readonly property real c1: Theme.bar.flareC1
    readonly property real c2: Theme.bar.flareC2

    // Fill
    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: Theme.colors.layer0

        startX: 0
        startY: 0

        PathCubic {
            x: root.f
            y: root.h
            control1X: root.c1
            control1Y: 0
            control2X: root.c2
            control2Y: root.h
        }

        PathLine { x: root.w - root.f; y: root.h }

        PathCubic {
            x: root.w
            y: 0
            control1X: root.w - root.c2
            control1Y: root.h
            control2X: root.w - root.c1
            control2Y: 0
        }

        PathLine { x: 0; y: 0 }
    }

    // Border on flares + bottom edge only (top edge sits on the screen bezel)
    ShapePath {
        strokeWidth: 2
        strokeColor: Theme.colors.primary
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap

        startX: 0
        startY: 0

        PathCubic {
            x: root.f
            y: root.h - 1          // 1px inset keeps the outer pixel of the stroke
            control1X: root.c1
            control1Y: 0
            control2X: root.c2
            control2Y: root.h - 1
        }

        PathLine { x: root.w - root.f; y: root.h - 1 }

        PathCubic {
            x: root.w
            y: 0
            control1X: root.w - root.c2
            control1Y: root.h - 1
            control2X: root.w - root.c1
            control2Y: 0
        }
    }
}
