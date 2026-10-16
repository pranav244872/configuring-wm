// Session lock host: real WlSessionLock (never a fake overlay). Unlocking is
// sessionLock.locked = false (WlSessionLock.unlock() is private in 0.3.2).
// IPC has lock/unlock/isLocked so a TTY can recover without killing qs.
//
// Naming: host ids are sessionLock/authState (NOT lock/auth) because the
// surface declares its own lock/auth properties, which would shadow the ids
// and self-bind (binding loop, null auth, dead surface).
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

    function engage() {
        authState.reset();
        sessionLock.locked = true;
        // TEMPORARY safety net: release the lock if input is dead.
        safetyTimer.restart();
    }

    function disengage() {
        safetyTimer.stop();
        authState.reset();
        sessionLock.locked = false;
    }

    // TEMPORARY: auto-unlock 15s after engaging. Remove once password
    // auth is proven live.
    Timer {
        id: safetyTimer
        interval: 15000
        onTriggered: {
            if (sessionLock.locked)
                host.disengage();
        }
    }
}
