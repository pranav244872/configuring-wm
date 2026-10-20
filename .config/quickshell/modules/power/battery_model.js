// Pure battery-warning decisions. Kept out of the QML so the threshold table
// can be exercised without draining the machine (see preview_notifications.qml).
//
// One warning per level per discharge: 20% low, 10% critical. Rearms above 25%
// (hysteresis); the caller clears the flags and the toasts when the charger
// goes in.

// level: current percent (0-100)
// Returns { warn, warnedLow, warnedCritical } -- the flags are the next state.
function decide(level, warnedLow, warnedCritical, low, critical, rearm) {
    if (level > rearm)
        return { warn: false, warnedLow: false, warnedCritical: false };

    if (level <= critical)
        return { warn: !warnedCritical, warnedLow: true, warnedCritical: true };

    // A critical warning that is already up covers the low level: skipping
    // straight past 20% must not queue two toasts.
    if (level <= low && !warnedLow && !warnedCritical)
        return { warn: true, warnedLow: true, warnedCritical: false };

    // Critical already up: the low level is covered by it.
    return { warn: false, warnedLow: warnedLow || warnedCritical,
             warnedCritical: warnedCritical };
}
