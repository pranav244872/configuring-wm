// Soft elevation shadow for card/pill surfaces.
import QtQuick
import QtQuick.Effects
import qs.modules

RectangularShadow {
    id: shadow

    required property var target

    anchors.fill: target
    radius: target.radius ?? 0
    topLeftRadius: target.topLeftRadius ?? (target.radius ?? 0)
    topRightRadius: target.topRightRadius ?? (target.radius ?? 0)
    bottomLeftRadius: target.bottomLeftRadius ?? (target.radius ?? 0)
    bottomRightRadius: target.bottomRightRadius ?? (target.radius ?? 0)
    blur: Theme.sizes.elevation * 0.9
    offset: Qt.vector2d(0, 1)
    spread: 1
    color: Theme.colors.shadow
    cached: true
}