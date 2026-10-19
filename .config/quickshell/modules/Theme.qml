// ~/.config/quickshell/modules/Theme.qml
//
// THE design system for our own quickshell UI.
//
//   palette      raw Material-3 roles  <- the only place hex codes live
//   colors       semantic roles        <- computed from palette (ColorUtils)
//   rounding     corner radius scale
//   font         families + sizes
//   sizes        component dimensions
//   animation    motion tokens (durations + curves, our own fast values)
//   transparency surface opacity knobs (static for now, hook for dynamic later)
//
// The palette is seeded from the Material/teal scheme already used by Hyprland
// (~/.config/hypr/modules/colors.lua) and kitty, so every UI piece matches.
//
// Swapping the theme later (wallpaper-derived colours, a second palette, a
// generator like matugen) means replacing the values in `palette` only -
// components consume the semantic `colors` and never a hex code.
//
// Structure follows end-4/dots-hyprland's Appearance.qml.

pragma Singleton

import QtQuick
import qs.modules

QtObject {
    id: theme

    // ============================================================== palette
    readonly property QtObject palette: QtObject {
        readonly property color background:          "#0e1415"
        readonly property color surface:             "#1a2121"
        readonly property color surfaceLowest:       "#090f10"
        readonly property color surfaceLow:          "#161d1d"
        readonly property color surfaceContainer:   "#1a2121"
        readonly property color surfaceHigh:         "#252b2c"
        readonly property color surfaceHighest:      "#303637"
        readonly property color fgSurface:           "#dee4e4"
        readonly property color fgSurfaceVariant:    "#bec8c9"
        readonly property color outline:             "#899393"
        readonly property color outlineVariant:      "#3f4849"
        readonly property color primary:             "#80d4dc"
        readonly property color fgPrimary:            "#00363b"
        readonly property color primaryContainer:    "#004f55"
        readonly property color fgPrimaryContainer:  "#9df0f9"
        readonly property color secondary:           "#b1cbce"
        readonly property color secondaryContainer:  "#324b4d"
        readonly property color tertiary:            "#b7c7ea"
        readonly property color error:               "#ffb4ab"
        readonly property color errorFg:            "#690005"
        readonly property color shadow:              "#000000"
        readonly property color scrim:               "#000000"
    }

    // ============================================================== colors
    // Semantic roles. Components may only use these, never palette.* directly.
    readonly property QtObject colors: QtObject {
        // Pill / popup surface: slightly lifted from background so it reads on any wallpaper.
        readonly property color layer0:      ColorUtils.overlay(
                                                palette.background,
                                                ColorUtils.transparentize(palette.surfaceHigh, 0.15))
        readonly property color layer1:      palette.surfaceContainer
        readonly property color layer2:      palette.surfaceHigh
        readonly property color layer3:      palette.surfaceHighest

        readonly property color fgLayer0:    palette.fgSurface
        readonly property color fgLayer1:    palette.fgSurface
        readonly property color fgLayer2:    palette.fgSurface

        readonly property color subtext:      palette.fgSurfaceVariant
        readonly property color outline:     ColorUtils.transparentize(palette.outlineVariant, 0.35)
        readonly property color outlineStrong: palette.outlineVariant

        readonly property color primary:     palette.primary
        readonly property color fgPrimary:   palette.fgPrimary
        readonly property color primaryContainer: palette.primaryContainer
        readonly property color fgPrimaryContainer: palette.fgPrimaryContainer

        readonly property color barTrack:    ColorUtils.transparentize(palette.outlineVariant, 0.55)
        readonly property color error:       palette.error
        readonly property color errorFg:     palette.errorFg
        readonly property color warning:     "#f9c74f"      // battery / caution accents
        readonly property color shadow:      ColorUtils.transparentize(palette.shadow, 0.55)
        readonly property color scrim:       ColorUtils.transparentize(palette.scrim, 0.5)

        // M3 state layers (on-colour at low alpha)
        readonly property color stateHover:  ColorUtils.transparentize(palette.fgSurface, 0.92)   // 8 %
        readonly property color stateActive: ColorUtils.transparentize(palette.fgSurface, 0.88)   // 12 %
    }

    // ============================================================== rounding
    readonly property QtObject rounding: QtObject {
        readonly property int hairline: 2
        readonly property int xs: 4
        readonly property int sm: 8
        readonly property int md: 12
        readonly property int lg: 16
        readonly property int xl: 22
        readonly property int full: 9999
    }

    // ============================================================== font
    readonly property QtObject font: QtObject {
        // Chaldea speaks in monospace everywhere: labels, values, titles.
        // JetBrains Mono (ttf-jetbrains-mono) carries the tracked-out look.
        readonly property string main:  "JetBrains Mono"
        readonly property string mono:  "JetBrains Mono"
        // Icon font: Material Symbols (extra/ttf-material-symbols-variable).
        // Icons are written as *ligature names* ("volume_up"), not codepoints -
        // same trick end-4/dots-hyprland and caelestia-dots/shell use.
        readonly property string icon:  "Material Symbols Rounded"
        readonly property QtObject size: QtObject {
            readonly property int xs:   11
            readonly property int sm:   13
            readonly property int md:   15
            readonly property int lg:   18
            readonly property int xl:   22
        }
    }

    // ============================================================== sizes
    readonly property QtObject sizes: QtObject {
        readonly property int osdWidth:      260
        readonly property int osdHeight:     72
        readonly property int osdBottom:     44     // gap from the bottom edge
        // Session menu panel. Fits "SHUT DOWN" + icon at font.size.md with
        // tracking; the panel is content-sized in height, fixed in width.
        readonly property int sessionWidth:  220

        // Dashboard (bottom sheet): deliberately narrower than the screen, a
        // fixed share of the monitor height, so the sections scroll.
        readonly property int  dashboardWidth:       720
        readonly property real dashboardHeightRatio: 0.40
        // Tab row: numbered equal-width slots with a solid block behind the
        // active one (the bar's workspace treatment). `dashboardTabInset` is
        // the block's breathing room inside its cell.
        readonly property int  dashboardTabHeight: 34
        readonly property int  dashboardTabInset:  3
        readonly property int elevation:     10
        readonly property int iconSize:      30
        readonly property int barThickness:  4
        readonly property int barLength:     150
        // The bar is only 4px tall; the slot is just tall enough to hold it, and the
        // drag target is inflated from there (see Slider.qml). Keeping the slot
        // tight is what pulls the bar up next to the label - with a tall slot the
        // text floats away from the slider it labels.
        readonly property int sliderSlot:    8
        readonly property int sliderHandle:  12
        readonly property int sliderGrabPad: 6    // hit area padding above/below

        // Asymmetric, like end-4's OsdValueIndicator (left 10 / right 20):
        // "an icon is circle ish, a column isn't, hence the extra padding".
        readonly property int padding:       12
        readonly property int paddingEnd:    20

        // gaps between elements (spacing scale, mirrors rounding)
        readonly property int xs:            4
        readonly property int md:            12
    }

    // ============================================================== frame
    // Chaldea frame language: 1px hairline borders, square corners, accent
    // corner ticks, tracked-out uppercase micro-labels, 1px divider rules.
    // Our teal stays the accent; only the shapes change.
    readonly property QtObject frame: QtObject {
        readonly property int line:        1       // hairline border/rule width
        readonly property int tick:        7       // corner tick arm length
        readonly property int tracking:    2       // micro-label letter spacing
        readonly property int titleTrack:   3       // header title letter spacing
        readonly property int labelSize:    11      // micro-label pixel size
        readonly property int margins:      18      // frame content margins
    }
    // ============================================================== bar
    // Bar geometry tokens. The island is a square Chaldea frame now; the old
    // flare tokens are gone with the curves.
    readonly property QtObject bar: QtObject {
        readonly property int height:    30      // bar body height
        readonly property int pad:       14      // inner horizontal padding

        // Workspace slots: active block centred (2px inset), trailing between
        // slots while gliding.
        readonly property int chipSize:      26
        readonly property int pillSize:      22
        readonly property int dockHalf:       9   // text colour band around the slot centre

        readonly property int clockSize:   Theme.font.size.sm
        readonly property int clockWeight: Font.DemiBold
    }

    // ============================================================== screenshot
    // Screenshot + annotation tokens. Pen colours are a fixed standard set,
    // not palette roles.
    readonly property QtObject screenshot: QtObject {
        readonly property int toolbarHeight: 56
        readonly property int toolSize:      40
        readonly property int swatchSize:    22
        readonly property int minSelect:     8
        readonly property var penWidths: [3, 5, 8]
        readonly property var penColors: ["#ffffff", "#000000", "#ff5252",
                                          "#ffd740", "#69f0ae", "#448aff"]
        // Transparency checkerboard (fixed pair, like the pen set)
        readonly property var checker: ["#283132", "#202829"]
    }

    // ============================================================== notifications
    // Toast stack + history. Durations are omarchy's policy: a minimum per
    // urgency, stretched up to `maxDuration` when the sender asks for longer,
    // and no timer at all for critical (lifetime 0 == sticky). The card
    // countdown ticks at `tick` ms and pauses while the pointer is over it.
    readonly property QtObject notifications: QtObject {
        readonly property int width:        340     // toast card width
        readonly property int gap:          8       // between stacked cards
        readonly property int topOffset:    50      // 30 bar + 12 gaps_out + 8 breathing
        readonly property int sideOffset:   20      // 12 gaps_out + 8
        readonly property int maxVisible:   4       // overflow goes straight to history
        readonly property int historyLimit: 20
        readonly property int lowDuration:    5000
        readonly property int normalDuration: 8000
        readonly property int maxDuration:   30000  // sender-stretched cap
        readonly property int tick:            50   // countdown resolution
        readonly property int avatar:          34   // icon slot edge
        readonly property int bodyLines:        3   // body is elided past this
    }

    // ============================================================== wallpaper
    // Carousel picker (a bottom sheet, like the dashboard) and the background
    // surface. The sheet is wider than the dashboard because a filmstrip needs
    // room: slides are 16:9, ~4 of them visible, and the centred one carries
    // the accent border and grows a little. Side slides dim, no rotation --
    // our language is flat (see notes/wallpaper.md).
    readonly property QtObject wallpaper: QtObject {
        // 18 margins + 16 label row + 10 + 1 rule + 12 + strip (see below)
        readonly property int  sheetWidth:        960
        // strip = 126 slide + 2*6 scale pad + 10 gap + 16 label = 164, plus the
        // 18px frame margins top and bottom: 36 + 16 + 10 + 1 + 12 + 164.
        readonly property int  sheetHeight:       240
        readonly property int  slideWidth:        224
        readonly property int  slideHeight:       126   // 16:9 of slideWidth
        readonly property int  slideGap:          10
        readonly property int  labelHeight:       16    // header row + slide label row
        readonly property real neighbourAlpha:    0.5   // side slides
        // The centred slide grows by this much (the strip reserves the room, so
        // nothing is clipped). ~8% reads as "picked" without moving the labels.
        readonly property real slideFocusScale:   1.08
        readonly property int  labelGap:          10
        // The slide is a hairline frame; the centred one doubles the border to
        // read like a focused Hyprland window (2px, our border_size).
        readonly property int  focusBorder:       2
    }

    // ============================================================== animation
    // Our own values: fast, matching the Hyprland feel (see gotchas.md ->
    // animation speed units). end-4's 350-650ms "expressive" curves feel slow here.
    readonly property QtObject animation: QtObject {
        // easeOutQuint, same curve family as our Hyprland decorations.lua
        readonly property var curveOut: [0.22, 1, 0.36, 1]
        readonly property var curveIn:  [0.55, 0, 1, 0.45]

        // end-4 "expressive" overshoot for things that move (glide/slide/grow).
        // Kept inside our 120-200ms rule: fast beats fancy.
        readonly property var curveMove: [0.38, 1.21, 0.22, 1]
        readonly property int moveDuration: 70

        readonly property int enterDuration: 160
        readonly property int exitDuration:  120
        readonly property int valueDuration: 140

        // Used where the animation is always the same. Show/hide animations
        // can't use this: a Behavior may not swap its animation while running,
        // so those bind duration/easing to `showing` inline instead.
        readonly property Component value: Component {
            NumberAnimation {
                duration: theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: theme.animation.curveOut
            }
        }
    }

    // ============================================================== transparency
    // Static for now. Later: derive these from the wallpaper (like end-4's
    // ColorQuantizer) without touching any component.
    readonly property QtObject transparency: QtObject {
        readonly property real background: 0.0
        readonly property real content:    1.0
    }

    // ============================================================== icons
    // Material Symbols *ligature names*, resolved by the icon font at render
    // time. Do NOT use private-use codepoints here: QML's \u escape is exactly
    // 4 hex digits, and Nerd Font PUA glyphs have ~zero advance width in Qt,
    // so they render as a clipped sliver. See gotchas.md.
    readonly property QtObject glyphs: QtObject {
        readonly property string volumeUp:    "volume_up"
        readonly property string volumeDown:  "volume_down"
        readonly property string volumeMute:  "volume_mute"

        readonly property string brightness1: "brightness_1"
        readonly property string brightness2: "brightness_2"
        readonly property string brightness3: "brightness_3"
        readonly property string brightness4: "brightness_4"
        readonly property string brightness5: "brightness_5"
        readonly property string brightness6: "brightness_6"
        readonly property string brightness7: "brightness_7"

        readonly property string shotFull:   "fullscreen"
        readonly property string shotRegion:  "crop"
        readonly property string shotWindow:  "select_window"
        readonly property string shotPen:     "edit"
        readonly property string shotWidth:   "line_weight"
        readonly property string shotText:    "text_fields"
        readonly property string shotUndo:    "undo"
        readonly property string shotRedo:    "redo"
        readonly property string shotClear:   "delete"
        readonly property string shotSave:    "save"
        readonly property string shotCopy:    "content_copy"
        readonly property string shotDiscard: "close"
        readonly property string shotReselect: "refresh"
        readonly property string shotResize: "south_east"

        readonly property string caffeine: "coffee"

        // Session / power menu
        readonly property string powerLock:     "lock"
        readonly property string powerLogout:   "logout"
        readonly property string powerSuspend:  "bedtime"
        readonly property string powerReboot:   "restart_alt"
        readonly property string powerShutdown: "power_settings_new"

        // Network / wifi. Signal strength is drawn as a bar meter
        // (widgets/SignalBars) rather than a glyph: rotating a glyph spinner
        // pixelates, because StyledText renders with Text.NativeRendering.
        readonly property string wifiOff:    "signal_wifi_off"
        readonly property string wifiFind:   "wifi_find"
        readonly property string wifiSecure: "lock"
        readonly property string wifiScan:   "refresh"
        readonly property string revealOn:   "visibility"
        readonly property string revealOff:  "visibility_off"
        readonly property string wifiForget: "delete"

        // Notifications
        readonly property string notifBell:  "notifications"
        readonly property string notifDnd:   "notifications_off"
        readonly property string notifClose: "close"
        readonly property string wallpaperApplied: "check"
    }
}