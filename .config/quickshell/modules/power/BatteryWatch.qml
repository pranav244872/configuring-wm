// Battery watch: the one UPower reading the bar and the warnings share, plus
// the low-battery toast and hook.
//
// Adapted from Omarchy's battery service + `omarchy-battery-low`: warn once per
// level per discharge, 20% low and 10% critical, and run an extensible hook.
// Their version shells out to notify-send; ours is the notification daemon, so
// the toast is local (no libnotify, no D-Bus round trip).
//
// Event-driven: UPower emits on its own cadence, so there is no polling timer.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import qs.modules.notifications
import "battery_model.js" as BatteryModel

QtObject {
    id: root

    readonly property var device: UPower.displayDevice

    // `ready` matters: the device object exists before UPower's first GetAll
    // lands, and until then `percentage` reads 0 -- which the warning path took
    // as a real 0% (fired a bogus critical toast on 2026-10-20).
    readonly property bool present: !!root.device && root.device.ready && !!root.device.isPresent
    // 1.0 until UPower is ready, matching the bar's old fallback.
    readonly property real pct: root.present ? root.device.percentage : 1.0
    readonly property int state: root.device ? root.device.state : UPowerDeviceState.Unknown

    readonly property bool charging: [UPowerDeviceState.Charging,
                                      UPowerDeviceState.FullyCharged,
                                      UPowerDeviceState.PendingCharge].includes(root.state)

    // Both signals: either alone lies for a moment right after a plug event.
    readonly property bool discharging: root.present && UPower.onBattery
                                        && root.state === UPowerDeviceState.Discharging

    readonly property int level: Math.round(root.pct * 100)

    readonly property int lowLevel: 20
    readonly property int criticalLevel: 10
    // Above this the warnings rearm (hysteresis against a level hovering at 20).
    readonly property int rearmLevel: 25

    property bool warnedLow: false
    property bool warnedCritical: false

    // Ids of the toasts this service put up, so the charger appearing takes
    // them down again.
    property var warningIds: []

    readonly property string hookPath: (Quickshell.env("XDG_CONFIG_HOME")
                                        || (Quickshell.env("HOME") + "/.config"))
                                       + "/quickshell/hooks/battery-low"

    readonly property Process hook: Process {
        // Executable hook, level as $1 (Omarchy's `battery-low <percent>`).
        command: ["sh", "-c", 'h="$1"; shift; [ -x "$h" ] && exec "$h" "$@"',
                  "sh", root.hookPath]
    }

    onLevelChanged: root.check()

    // Charging: forget the warnings and clear their toasts. Unplugging runs the
    // check immediately instead of waiting for the next percentage tick.
    onDischargingChanged: root.discharging ? root.check() : root.rearm()

    Component.onCompleted: Qt.callLater(root.check)

    // "1h 12m" from UPower's seconds (or an explicit count for the bench), ""
    // when it does not know yet.
    function timeText(seconds) {
        const value = Number(seconds === undefined
                             ? (root.device ? root.device.timeToEmpty : 0) : seconds);
        if (!isFinite(value) || value <= 0)
            return "";
        const minutes = Math.round(value / 60);
        return Math.floor(minutes / 60) + "h " + String(minutes % 60).padStart(2, "0") + "m";
    }

    function isCritical(level) {
        return level <= root.criticalLevel;
    }

    // Copy lives here so the bench renders the real strings.
    function summaryFor(level) {
        return root.isCritical(level) ? "BATTERY CRITICAL" : "BATTERY LOW";
    }

    function bodyFor(level, seconds) {
        if (root.isCritical(level))
            return level + "% left · plug in now";
        const time = root.timeText(seconds);
        return level + "% left · " + (time.length > 0 ? time : "plug in soon");
    }

    function warn(level) {
        const at = Math.max(0, Math.min(100, Math.round(Number(level) || 0)));
        const id = NotificationService.post({
            app: "BATTERY",
            appIcon: "battery-caution",
            summary: root.summaryFor(at),
            body: root.bodyFor(at),
            urgency: root.isCritical(at) ? NotificationUrgency.Critical
                                         : NotificationUrgency.Normal,
            // The reference gives the low warning 30 s; critical is sticky.
            expireTimeout: root.isCritical(at) ? 0 : 30000
        });
        root.warningIds = root.warningIds.concat([id]);
        root.runHook(at);
        return id;
    }

    function runHook(level) {
        root.hook.command = ["sh", "-c", 'h="$1"; shift; [ -x "$h" ] && exec "$h" "$@"',
                             "sh", root.hookPath, String(level)];
        root.hook.running = true;
    }

    function rearm() {
        root.warnedLow = false;
        root.warnedCritical = false;
        root.clearWarnings();
    }

    function clearWarnings() {
        for (let i = 0; i < root.warningIds.length; i++)
            NotificationService.dismissLocal(root.warningIds[i]);
        root.warningIds = [];
    }

    function check() {
        if (!root.present || !root.discharging)
            return;
        const next = BatteryModel.decide(root.level, root.warnedLow, root.warnedCritical,
                                         root.lowLevel, root.criticalLevel, root.rearmLevel);
        root.warnedLow = next.warnedLow;
        root.warnedCritical = next.warnedCritical;
        if (next.warn)
            root.warn(root.level);
    }
}
