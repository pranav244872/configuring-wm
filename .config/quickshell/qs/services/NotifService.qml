pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// NotifService.qml — Centralized notification state
//
// SAFETY:
//   - Notification QObjects are kept alive via tracked=true
//   - Removal always: (1) removes from array, (2) then untracks via Qt.callLater
//   - Signal connections use notifId capture (not the QObject) to avoid dangling refs
//   - Timers use static Timer + queue pattern instead of Qt.createQmlObject
//   - history uses plain JS snapshots (safe after QObject is freed)

Singleton {
    id: root

    property alias server: server
    property var popups: []      // live Notification QObjects — used by NotificationPopup ListView
    property var history: []     // plain JS snapshots — read-only; safe after QObject is freed
    property bool dnd: false     // Do Not Disturb — suppresses popups, still logs history

    // Internal: pending auto-dismiss queue (replaces Qt.createQmlObject timers)
    property var _dismissQueue: ({})  // notifId → timestamp when it should be dismissed

    // Expose count helper for badge dots
    readonly property int historyCount: history.length
    readonly property int popupCount: popups.length

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            // Keep the QObject alive while it's in the popups list
            notification.tracked = true

            const notifId = notification.id

            // --- History snapshot (always, even in DND) ---
            const snapshot = {
                id:       notifId,
                appName:  notification.appName  || "",
                summary:  notification.summary  || "",
                body:     notification.body     || "",
                icon:     notification.appIcon  || "",
                iconName: notification.appIcon  || "",
                actions:  [],   // history items are read-only; no invoke
                time:     new Date(),
            }
            history = [snapshot, ...history]

            // --- DND: skip live popup ---
            if (root.dnd) {
                Qt.callLater(() => {
                    try { notification.tracked = false } catch (e) {}
                })
                return
            }

            // --- Add to live popup list ---
            popups = [...popups, notification]

            // Wire the protocol close signal (e.g. app calls CloseNotification)
            // Capture only notifId (a number), NOT the QObject, to avoid dangling refs
            notification.closed.connect(function() {
                root.safeRemoveById(notifId)
            })

            // --- Schedule auto-dismiss ---
            // expireTimeout: -1 = never, 0 = server default, >0 = ms
            let timeout = (notification.expireTimeout > 0) ? notification.expireTimeout : 5000
            root._dismissQueue[notifId] = Date.now() + timeout
        }
    }

    // Single static timer that checks the dismiss queue every 500ms
    // This replaces all per-notification Qt.createQmlObject timers
    Timer {
        id: dismissTimer
        interval: 500
        running: root.popups.length > 0
        repeat: true
        onTriggered: {
            const now = Date.now()
            const queue = root._dismissQueue
            const toRemove = []

            for (const id in queue) {
                if (queue[id] <= now) {
                    toRemove.push(Number(id))
                }
            }

            for (const id of toRemove) {
                delete queue[id]
                root.safeRemoveById(id)
            }
        }
    }

    // Safe removal: guards against accessing freed QObjects
    function safeRemoveById(notifId) {
        const id = Number(notifId)

        // Clean up dismiss queue entry
        if (root._dismissQueue[id]) {
            delete root._dismissQueue[id]
        }

        let temp = popups.slice()
        let idx = -1

        // Safe index search: guard property access with try/catch
        for (let i = 0; i < temp.length; i++) {
            try {
                if (Number(temp[i].id) === id) {
                    idx = i
                    break
                }
            } catch (e) {
                // QObject already freed — remove this dangling entry too
                temp.splice(i, 1)
                i--
            }
        }

        if (idx !== -1) {
            const notif = temp[idx]
            temp.splice(idx, 1)
            popups = temp                   // update list BEFORE releasing QObject

            Qt.callLater(() => {            // give ScriptModel time to update
                try { notif.tracked = false } catch (e) {}
            })
        } else if (temp.length !== popups.length) {
            // We cleaned up dangling entries during search
            popups = temp
        }
    }

    // Called by the close button or action button in NotificationCard
    function removePopup(notification) {
        try {
            const notifId = Number(notification.id)
            safeRemoveById(notifId)
        } catch (e) {
            // notification QObject may already be freed — clean up the array
            cleanupDanglingPopups()
        }
    }

    // Scan popups for any freed QObjects and remove them
    function cleanupDanglingPopups() {
        let temp = popups.slice()
        let changed = false
        for (let i = temp.length - 1; i >= 0; i--) {
            try {
                // Test if the QObject is still alive by accessing a property
                void temp[i].id
            } catch (e) {
                temp.splice(i, 1)
                changed = true
            }
        }
        if (changed) {
            popups = temp
        }
    }

    // Remove a single entry from history (called by side panel history X button)
    function removeFromHistory(notifId) {
        const id = Number(notifId)
        history = history.filter(n => Number(n.id) !== id)
    }

    function clearHistory() {
        history = []
    }
}
