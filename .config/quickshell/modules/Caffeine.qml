// Keep-awake ("caffeine") state: while on, the bar holds a wayland idle
// inhibitor, so the session is never marked idle. Our IdleService uses
// respectInhibitors, so this also stops the lock / screen-off / suspend timers.
//
// Deliberately NOT persisted (a temporary switch): it resets to off whenever
// quickshell restarts. Toggle by mouse (bar button) or `qs ipc call caffeine`.
//
// Note: a 0.3.2 singleton must root on a bare `QtObject` (no `Singleton` type),
// which has no default property - so the IpcHandler and the IdleInhibitor live
// in the bar (TopBar.qml), not here.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool enabled: false

    function toggle() {
        root.enabled = !root.enabled;
    }

    function setEnabled(value) {
        root.enabled = value;
    }
}
