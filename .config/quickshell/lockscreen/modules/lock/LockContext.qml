// LockContext.qml — Shared lockscreen state and PAM authentication
//
// This Scope holds all state shared between lock surfaces on each monitor.
// Contains PamContext, current password text, unlock progress, and failure state.
// Auto-unlocks after 10 seconds for development safety.

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    // Emitted when authentication succeeds
    signal unlocked()

    // These properties are shared across all monitors
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    // Clear failure text when user starts typing again
    onCurrentTextChanged: showFailure = false

    // Start PAM authentication with current password
    function tryUnlock() {
        if (currentText === "") return

        root.unlockInProgress = true
        pam.start()
    }

    // PAM authentication context
    PamContext {
        id: pam

        // Use custom PAM config for password-only auth
        configDirectory: "pam"
        config: "password.conf"

        // When PAM requests a response, send the current password
        onPamMessage: {
            if (this.responseRequired) {
                this.respond(root.currentText)
            }
        }

        // Handle authentication result
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
            }

            root.unlockInProgress = false
        }
    }

    // Development safety: auto-unlock after 10 seconds
    // Timer is NOT started automatically — it's reset when the lock is activated
    Timer {
        id: autoUnlockTimer
        interval: 10000
        running: false
        repeat: false
        onTriggered: {
            console.log("LockContext: AUTO-UNLOCK after 10s (development safety)")
            root.unlocked()
        }
    }

    // Reset auto-unlock timer when locked
    function resetAutoUnlock() {
        autoUnlockTimer.restart()
    }
}
