// Session lock host: real WlSessionLock (never a fake overlay). Unlocking is
// sessionLock.locked = false (WlSessionLock.unlock() is private in 0.3.2).
// IPC has lock/unlock/isLocked so a TTY can recover without killing qs.
// NOTE: host ids must not be lock/auth (surface props would shadow them).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.lock

Scope {
    id: host

    WlSessionLock {
        id: sessionLock

        LockSurface {
            lock: sessionLock
            auth: authState
        }
    }

    LockAuth {
        id: authState
        // The password path unlocks directly — route it through disengage() too,
        // or LockState stays set (that bug shut every guarded surface on
        // 2026-10-19 until the shell was restarted).
        onUnlocked: host.disengage()
    }

    IdleService {
        onLockRequested: host.engage()
    }

    Connections {
        target: sessionLock
        function onSecureStateChanged() {
            if (sessionLock.secure)
                authState.reset();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            host.engage();
        }

        function unlock(): void {
            host.disengage();
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }
    }

    // Lock/unlock paths: idle and the Fn+F9 bind reach engage(); the password
    // path (LockAuth.unlocked, above) and `qs ipc call lock unlock` reach
    // disengage(). LockState is set from these rather than from a
    // `lockedChanged` signal, because 0.3.2's WlSessionLock does not notify
    // `locked` on the way back to false (verified 2026-10-19).
    function engage() {
        authState.reset();
        sessionLock.locked = true;
        LockState.locked = true;
    }

    function disengage() {
        authState.reset();
        sessionLock.locked = false;
        LockState.locked = false;
    }

    // Backstop, for the same reason: `locked` always *reads* correctly, it just
    // does not notify. A missed path must not leave the guards stuck again.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (LockState.locked !== sessionLock.locked)
                LockState.locked = sessionLock.locked;
        }
    }
}
