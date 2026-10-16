// Text with our font tokens applied by default.
// Override any property (color, font.pixelSize, ...) as usual.

import QtQuick
import qs.modules

Text {
    color: Theme.colors.fgLayer0
    font.family: Theme.font.main
    font.pixelSize: Theme.font.size.sm
    font.weight: Font.Medium
    renderType: Text.NativeRendering
}