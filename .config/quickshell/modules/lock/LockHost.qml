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
        onUnlocked: sessionLock.locked = false
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

    // Every lock/unlock path in the shell goes through these two (idle, the
    // Fn+F9 bind via IPC, `qs ipc call lock`), so they are the source of truth
    // for LockState. It is set here rather than from a `lockedChanged` signal:
    // 0.3.2's WlSessionLock does not notify `locked` on the way back to false
    // (verified 2026-10-19 -- the flag then stuck, and the guards below refused
    // to open anything for the rest of the session).
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
}
