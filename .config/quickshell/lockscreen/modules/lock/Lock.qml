// Lock.qml — Root lockscreen component
//
// Wires together LockContext (shared state + PAM) and WlSessionLock.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property alias lock: sessionLock

    // Shared state: PAM auth, current text, unlock progress
    LockContext {
        id: lockContext

        onUnlocked: {
            sessionLock.unlock()
        }
    }

    // Wayland session lock
    WlSessionLock {
        id: sessionLock

        signal unlock

        Component.onCompleted: {
            lockContext.resetAutoUnlock()
        }

        // LockSurface IS a WlSessionLockSurface — use it directly
        LockSurface {
            context: lockContext
            lock: sessionLock
        }
    }
}
