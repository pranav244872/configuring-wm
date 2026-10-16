// Icon selection: value -> icon name.
pragma Singleton

import QtQuick
import qs.modules

QtObject {
    // Material Symbols volume states.
    function volume(value: real, muted: bool): string {
        if (muted)
            return Theme.glyphs.volumeMute;
        return value >= 0.35 ? Theme.glyphs.volumeUp : Theme.glyphs.volumeDown;
    }

    // Seven bins for brightness.
    function brightness(value: real): string {
        const bins = [
            Theme.glyphs.brightness1,
            Theme.glyphs.brightness2,
            Theme.glyphs.brightness3,
            Theme.glyphs.brightness4,
            Theme.glyphs.brightness5,
            Theme.glyphs.brightness6,
            Theme.glyphs.brightness7
        ];
        const clamped = Math.max(0, Math.min(1, value));
        return bins[Math.min(bins.length - 1, Math.floor(clamped * bins.length))];
    }

    // Battery bins inspired by caelestia-shell and DMS.
    function battery(percentage: real, charging: bool): string {
        const pct = Math.max(0, Math.min(1, percentage));
        const level = Math.round(pct * 100);

        if (charging) {
            if (level >= 95) return "battery_charging_full";
            if (level >= 85) return "battery_charging_90";
            if (level >= 70) return "battery_charging_80";
            if (level >= 55) return "battery_charging_60";
            if (level >= 40) return "battery_charging_50";
            if (level >= 25) return "battery_charging_30";
            return "battery_charging_20";
        } else {
            if (level >= 95) return "battery_full";
            if (level >= 85) return "battery_6_bar";
            if (level >= 70) return "battery_5_bar";
            if (level >= 55) return "battery_4_bar";
            if (level >= 40) return "battery_3_bar";
            if (level >= 25) return "battery_2_bar";
            if (level >= 10) return "battery_1_bar";
            return "battery_alert";
        }
    }
}