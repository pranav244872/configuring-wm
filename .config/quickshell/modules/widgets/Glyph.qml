// Material Symbols icon. The icon *name* lives in Theme.glyphs so components
// never hard-code a ligature string.
//
// Why an icon font and ligature names: Qt draws each glyph clipped to its
// advance width, and private-use codepoints (Nerd Fonts and friends) carry
// near-zero advances - the icon renders as a sliver. Material Symbols gives
// real metrics and lets us write "volume_up" instead of a codepoint.
// Same approach as end-4/dots-hyprland (widgets/MaterialSymbol.qml).
//
// The size is fixed on purpose: which icon shows depends on the value (see
// Icons.qml), never on how big it is - a resizing icon would resize the pill.

import QtQuick
import qs.modules

Text {
    color: Theme.colors.primary
    font.family: Theme.font.icon
    font.pixelSize: Theme.sizes.iconSize
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferNoHinting
}