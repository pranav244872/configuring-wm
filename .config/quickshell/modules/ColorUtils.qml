// ~/.config/quickshell/modules/ColorUtils.qml
//
// Colour maths used by Theme.qml. Kept tiny on purpose: every colour we show
// is *derived* from the palette here, never hand-written twice.
// Inspired by the approach in end-4/dots-hyprland and caelestia-dots/shell.

pragma Singleton

import QtQuick

QtObject {
    // Blend two colours. amount = 0 -> a, amount = 1 -> b.
    function mix(a, b, amount) {
        const t = amount;
        return Qt.rgba(
            a.r * (1 - t) + b.r * t,
            a.g * (1 - t) + b.g * t,
            a.b * (1 - t) + b.b * t,
            1);
    }

    // Reduce opacity. amount = 0 -> unchanged, 1 -> fully transparent.
    function transparentize(c, amount) {
        return Qt.rgba(c.r, c.g, c.b, c.a * (1 - amount));
    }

    // Simple alpha composite: `over` painted on top of `under`.
    function overlay(under, over) {
        const a = over.a;
        if (a <= 0) return under;
        if (a >= 1) return over;
        return Qt.rgba(
            over.r * a + under.r * (1 - a),
            over.g * a + under.g * (1 - a),
            over.b * a + under.b * (1 - a),
            1);
    }

    // Lift a surface towards its foreground colour - used for hover/active states.
    function lighten(c, amount) {
        return mix(c, "#ffffff", amount);
    }
}