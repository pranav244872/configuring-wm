// Launcher drawer body: the same flare block as BarSurface rotated 90 deg
// (curves into the LEFT screen edge), right corners rounded with
// Theme.rounding.lg, 2px primary border on exposed edges only.
import QtQuick
import QtQuick.Shapes
import qs.modules

Shape {
    id: root

    layer.enabled: true
    layer.samples: 4

    readonly property real f: Theme.bar.flare
    readonly property real c1: Theme.bar.flareC1
    readonly property real c2: Theme.bar.flareC2
    readonly property real r: Theme.rounding.lg

    // Fill
    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: Theme.colors.layer0

        startX: 0
        startY: 0

        PathCubic {
            x: root.f
            y: root.f
            control1X: 0
            control1Y: root.c1
            control2X: root.c2
            control2Y: root.f
        }

        PathLine { x: root.width - root.r; y: root.f }

        PathArc {
            x: root.width
            y: root.f + root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }

        PathLine { x: root.width; y: root.height - root.f - root.r }

        PathArc {
            x: root.width - root.r
            y: root.height - root.f
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }

        PathLine { x: root.f; y: root.height - root.f }

        PathCubic {
            x: 0
            y: root.height
            control1X: root.c2
            control1Y: root.height - root.f
            control2X: 0
            control2Y: root.height - root.c1
        }

        PathLine { x: 0; y: 0 }
    }

    // Border on top edge, right side, bottom edge + flares (1px inset on the
    // right so the outer stroke pixel survives the FBO clip)
    ShapePath {
        strokeWidth: 2
        strokeColor: Theme.colors.primary
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap

        startX: 0
        startY: 0

        PathCubic {
            x: root.f
            y: root.f
            control1X: 0
            control1Y: root.c1
            control2X: root.c2
            control2Y: root.f
        }

        PathLine { x: root.width - root.r - 1; y: root.f }

        PathArc {
            x: root.width - 1
            y: root.f + root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }

        PathLine { x: root.width - 1; y: root.height - root.f - root.r }

        PathArc {
            x: root.width - root.r - 1
            y: root.height - root.f
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Clockwise
        }

        PathLine { x: root.f; y: root.height - root.f }

        PathCubic {
            x: 0
            y: root.height
            control1X: root.c2
            control1Y: root.height - root.f
            control2X: 0
            control2Y: root.height - root.c1
        }
    }
}
