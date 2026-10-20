// Notification service: our shell *is* the daemon.
//
// Nothing else on this machine owns org.freedesktop.Notifications (no mako /
// dunst / swaync is installed), so this NotificationServer takes the bus name
// and our own UI draws the toasts: NotificationHost.qml owns the window and the
// IpcHandler, NotificationCard.qml owns the visuals.
//
// Logic only: a 0.3.2 singleton must root on a bare QtObject, which has no
// default property, so nothing visual can be declared here anyway.
//
// Policy (omarchy's, see notes/notifications.md):
//   durations   >=5s low, >=8s normal, sticky for critical, stretched up to
//               30s when the sender asks for longer; hover pauses the
//               countdown and new content restarts it
//   overflow    past maxVisible toasts the newest still shows and the oldest
//               leaves early, so a burst can never fill the screen
//   DND         persisted to ~/.cache/quickshell/notifications.json; a critical
//               notification from a command-line sender still gets through
//   history     session-only, plain data (never a live Notification object)
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.modules

QtObject {
    id: root

    // ---------------------------------------------------------------- server
    readonly property NotificationServer server: NotificationServer {
        // All three reference shells turn this off: with it on, a config reload
        // re-emits every notification still on screen as a fresh one.
        keepOnReload: false
        // Plain text only. `Text` is AutoText, so advertising markup would let
        // a body smuggle in an <img> and turn a toast into a remote GET
        // beacon; we render bodies with textFormat: PlainText.
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: true          // avatars, drawn as an Image (not markup)
        actionsSupported: true        // "default" action = click the toast
        actionIconsSupported: false
        inlineReplySupported: false
        persistenceSupported: false   // nothing writes to disk (v1)

        onNotification: (notification) => root.handle(notification)
    }

    // ----------------------------------------------------------------- model
    // The toast stack, newest first. A ListModel (not a JS array) so inserting
    // one toast does not rebuild the other delegates -- the countdown and the
    // hover pause of the toast you are reading live in those delegates.
    //
    // Rows hold *plain data*; the live Notification objects live in `liveRefs`
    // and are deliberately kept out of the model. A QObject in a ListModel role
    // becomes a dangling C++ pointer once the server destroys the notification,
    // and the next read of that role segfaults inside QQmlListModel::data
    // (omarchy documents the same crash).
    readonly property ListModel popups: ListModel {}

    // Every field a row carries. `notifId` and not `id`: a delegate declaring a
    // role as a property would collide with the item's own id attribute.
    readonly property var roles: ["notifId", "app", "appIcon", "summary", "body",
                                  "image", "urgency", "expireTimeout", "timestamp"]

    // Dismissed / expired toasts, newest first. Plain copies on purpose: the
    // object behind a row is gone once it leaves the screen, and reading a dead
    // wrapper throws (see gotchas.md).
    property var history: []

    // notifId -> Notification, for as long as the server holds it tracked.
    property var liveRefs: ({})

    readonly property int maxVisible: Theme.notifications.maxVisible
    readonly property int historyLimit: Theme.notifications.historyLimit

    // --------------------------------------------------------- do not disturb
    property bool doNotDisturb: false

    // Guards the write-back while the saved value is being loaded.
    property bool hydrating: false

    readonly property string statePath: (Quickshell.env("XDG_CACHE_HOME")
                                         || (Quickshell.env("HOME") + "/.cache"))
                                        + "/quickshell/notifications.json"

    // Same shape as the launcher's frequency cache: one tiny sh read at startup.
    readonly property Process stateLoader: Process {
        command: ["sh", "-c", "cat \"" + root.statePath + "\" 2>/dev/null || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.hydrating = true;
                try {
                    const saved = JSON.parse(text || "{}");
                    if (typeof saved.dnd === "boolean")
                        root.doNotDisturb = saved.dnd;
                } catch (e) {
                    // No state yet or a torn write: the defaults stand.
                }
                root.hydrating = false;
            }
        }

        Component.onCompleted: running = true
    }

    readonly property Process stateWriter: Process {
    }

    // Debounced: the toggle is a switch the user may flip a few times.
    readonly property Timer saveTimer: Timer {
        interval: 400
        onTriggered: root.writeState()
    }

    onDoNotDisturbChanged: if (!root.hydrating)
                                root.saveTimer.restart()

    function writeState() {
        // Only a bool goes in, so the JSON cannot carry a quote.
        root.stateWriter.command = ["sh", "-c",
            "mkdir -p \"$(dirname \"" + root.statePath + "\")\" && "
            + "printf '%s' '" + JSON.stringify({ dnd: root.doNotDisturb }) + "'"
            + " > \"" + root.statePath + "\""];
        root.stateWriter.running = true;
    }

    function toggleDnd() {
        root.setDnd(!root.doNotDisturb);
    }

    function setDnd(value) {
        root.doNotDisturb = !!value;
    }

    // ------------------------------------------------------------- durations
    // 0 means "never expires by itself" (critical, or a sender asking for a
    // resident notification). Everything else is floored per urgency and capped
    // so a rude sender cannot park a toast on screen for an hour.
    function durationFor(urgency, expireTimeout) {
        if (urgency === NotificationUrgency.Critical)
            return 0;
        const asked = Number(expireTimeout || 0);
        const requested = (isFinite(asked) && asked > 0) ? Math.round(asked) : 0;
        const floor = urgency === NotificationUrgency.Low ? Theme.notifications.lowDuration
                                                         : Theme.notifications.normalDuration;
        return Math.min(Theme.notifications.maxDuration, Math.max(floor, requested));
    }

    // ------------------------------------------------------------ DND bypass
    // Chat apps mark everything critical to force visibility, so urgency alone
    // is not enough: the sender also has to be a bare command line, i.e. a
    // script talking to the user directly rather than an app's brand name.
    readonly property var cliSenders: ["notify-send", "busctl", "gdbus"]

    function bypassesDnd(notification) {
        return root.cliSenders.indexOf(notification.appName || "") >= 0
            && notification.urgency === NotificationUrgency.Critical;
    }

    // A notification nobody looks back at: the freedesktop `transient` hint is
    // set ("popup only, do not store") or the sender never declared an
    // identity. Only decides whether a *silenced* one is worth recording --
    // once a toast has been on screen it lands in history like any other.
    function isEphemeral(notification) {
        return !!notification.transient || root.cliSenders.indexOf(notification.appName || "") >= 0;
    }

    // ------------------------------------------------------------- snapshots
    function snapshot(notification) {
        return {
            notifId: notification.id,
            app: notification.appName || "",
            appIcon: notification.appIcon || "",
            summary: notification.summary || "",
            body: notification.body || "",
            image: notification.image || "",
            urgency: notification.urgency,
            expireTimeout: Number(notification.expireTimeout || 0),
            timestamp: Date.now()
        };
    }

    // Copy a model row into plain data. The object get() hands back is only
    // valid while its row is in the model: after a remove() every role on it
    // reads back undefined, which is how an empty history entry gets written.
    function copyRow(row) {
        if (!row)
            return null;
        return {
            notifId: row.notifId,
            app: row.app,
            appIcon: row.appIcon,
            summary: row.summary,
            body: row.body,
            image: row.image,
            urgency: row.urgency,
            expireTimeout: row.expireTimeout,
            timestamp: row.timestamp
        };
    }

    function pushHistory(entry) {
        if (!entry)
            return;
        root.history = [entry].concat(root.history).slice(0, root.historyLimit);
    }

    // ----------------------------------------------------------------- intake
    function handle(notification) {
        // Must be the very first thing: an untracked notification is destroyed
        // the moment this handler returns, which would null out every reference
        // we just took (quickshell's own doc: "if this notification should not
        // be discarded, set its tracked property to true").
        notification.tracked = true;

        const row = root.snapshot(notification);
        root.liveRefs[row.notifId] = notification;
        notification.closed.connect(() => root.forgetRef(row.notifId, notification));

        if (root.doNotDisturb && !root.bypassesDnd(notification)) {
            // The toast never shows, so history is the only place a "what did I
            // miss while silenced" record can live.
            if (!root.isEphemeral(notification))
                root.pushHistory(row);
            // Nothing is on screen holding it open any more, so let the sender
            // go: an untracked notification is destroyed by the server.
            root.forgetRef(row.notifId, notification);
            notification.tracked = false;
            return;
        }

        root.watch(notification, row.notifId);

        // Mutating the model has to wait for the Repeater to finish incubating:
        // inserting mid-incubation crashes inside QV4::Object::insertMember.
        Qt.callLater(() => {
            root.dropSuperseded(row.notifId);
            root.dropDuplicates(row);
            root.trimToMax();
            root.popups.insert(0, row);
            // An update that landed while the insert was deferred found no row
            // to write to, and a property that already changed will not change
            // again -- so read the object once now that the row exists.
            root.refresh(notification, row.notifId);
        });
    }

    function forgetRef(notifId, notification) {
        // A newer notification may have taken the id over.
        if (root.liveRefs[notifId] === notification)
            delete root.liveRefs[notifId];
    }

    // A client updating a notification through replaces_id does not produce a
    // second onNotification: the server writes the new content onto the object
    // we already hold. The card draws a snapshot copied out of that object, so
    // nothing reaches the screen until we copy it again.
    readonly property var updateSignals: ["summaryChanged", "bodyChanged", "appNameChanged",
                                          "appIconChanged", "imageChanged", "urgencyChanged",
                                          "expireTimeoutChanged"]

    function watch(notification, notifId) {
        const refresh = () => root.refresh(notification, notifId);
        for (let i = 0; i < root.updateSignals.length; i++) {
            const signal = notification[root.updateSignals[i]];
            if (signal && typeof signal.connect === "function")
                signal.connect(refresh);
        }
    }

    function refresh(notification, notifId) {
        if (root.liveRefs[notifId] !== notification)
            return;
        let updated;
        try {
            updated = root.snapshot(notification);
        } catch (e) {
            return;   // torn down by the server while the signal was in flight
        }
        for (let i = 0; i < root.popups.count; i++) {
            const row = root.popups.get(i);
            if (!row || row.notifId !== notifId)
                continue;
            if (!root.rowChanged(row, updated))
                return;
            // The arrival time stays put: the delegate restarts its countdown
            // off the role change, and history should show when it first came in.
            updated.timestamp = row.timestamp;
            for (let r = 0; r < root.roles.length; r++)
                root.popups.setProperty(i, root.roles[r], updated[root.roles[r]]);
            return;
        }
    }

    function rowChanged(row, updated) {
        for (let r = 0; r < root.roles.length; r++) {
            const role = root.roles[r];
            if (role !== "timestamp" && row[role] !== updated[role])
                return true;
        }
        return false;
    }

    // A notification arriving under an id a toast on screen already holds
    // supersedes it: that row leaves. It is not archived -- the replacement
    // archives itself, and history would otherwise hold two entries for what
    // the sender means as one notification.
    function dropSuperseded(notifId) {
        for (let i = root.popups.count - 1; i >= 0; i--) {
            const row = root.popups.get(i);
            if (row && row.notifId === notifId)
                root.popups.remove(i);
        }
    }

    // A sender repeating a toast already on screen takes its place: the newest
    // copy stays, history keeps one entry, and the superseded copy is dismissed
    // at the server so its sender stops holding it open.
    function dropDuplicates(row) {
        for (let i = root.popups.count - 1; i >= 0; i--) {
            const other = root.popups.get(i);
            if (!other || other.app !== row.app || other.summary !== row.summary
                    || other.body !== row.body)
                continue;
            const ref = root.liveRefs[other.notifId];
            root.popups.remove(i);
            try {
                if (ref && ref.tracked)
                    ref.dismiss();
            } catch (e) {
                // Already torn down by the server -- nothing to release.
            }
        }
    }

    // The burst guard: the oldest toasts leave early (into history) so the
    // stack never grows past maxVisible.
    function trimToMax() {
        while (root.popups.count >= root.maxVisible)
            root.dismissPopup(root.popups.count - 1);
    }

    // --------------------------------------------------------------- actions
    function dismissPopup(index) {
        root.removePopup(index, false);
    }

    function expirePopup(index) {
        root.removePopup(index, true);
    }

    function removePopup(index, expired) {
        if (index < 0 || index >= root.popups.count)
            return;
        const row = root.popups.get(index);
        // Copy the row out before removing it -- see copyRow().
        const entry = root.copyRow(row);
        const ref = entry ? root.liveRefs[entry.notifId] : null;
        root.popups.remove(index);
        if (entry)
            root.pushHistory(entry);
        try {
            if (ref && ref.tracked) {
                if (expired && typeof ref.expire === "function")
                    ref.expire();
                else
                    ref.dismiss();
            }
        } catch (e) {
            // Already torn down by the server -- nothing to release.
        }
    }

    // Dismiss everything on screen (the oldest is at the bottom).
    function dismissAll() {
        while (root.popups.count > 0)
            root.removePopup(0, false);
    }

    // Dismiss the newest toast, i.e. the one being read.
    function dismissNewest() {
        root.removePopup(0, false);
    }

    // Clicking a toast runs its "default" action and takes the toast down. Most
    // chat apps register no action at all (they expect a click to focus their
    // window, which we do not do yet); then the click just dismisses.
    function invokeDefault(index) {
        if (index < 0 || index >= root.popups.count)
            return;
        const row = root.popups.get(index);
        const ref = row ? root.liveRefs[row.notifId] : null;
        try {
            if (ref && ref.actions) {
                for (let i = 0; i < ref.actions.length; i++) {
                    const action = ref.actions[i];
                    if (action && action.identifier === "default") {
                        action.invoke();
                        break;
                    }
                }
            }
        } catch (e) {
            // Already torn down by the server.
        }
        root.removePopup(index, false);
    }

    function invokeLast() {
        root.invokeDefault(0);
    }

    // ------------------------------------------------- shell-originated toasts
    // The shell's own warnings (low battery) share the stack and history without
    // a D-Bus client. There is no libnotify on this machine, and spawning
    // notify-send would need one; ids are negative so they cannot collide with
    // the server's, and there is no live Notification to track -- dismiss/expire
    // already handle a null ref.
    //
    // Deliberately ignores DND: a warning the shell raises itself is intentional.
    property int localSeq: 0

    function post(opts) {
        const row = {
            notifId: -(++root.localSeq),
            app: opts.app || "quickshell",
            appIcon: opts.appIcon || "",
            summary: opts.summary || "",
            body: opts.body || "",
            image: opts.image || "",
            urgency: opts.urgency !== undefined ? opts.urgency : NotificationUrgency.Normal,
            expireTimeout: Number(opts.expireTimeout || 0),
            timestamp: Date.now()
        };
        // Same incubation rule as handle(): the model must not change while the
        // Repeater is still creating delegates.
        Qt.callLater(() => {
            root.trimToMax();
            root.popups.insert(0, row);
        });
        return row.notifId;
    }

    // Take a shell-originated toast down (the battery warning once the charger
    // is in). Server toasts keep their own lifetimes.
    function dismissLocal(notifId) {
        for (let i = 0; i < root.popups.count; i++) {
            const row = root.popups.get(i);
            if (row && row.notifId === notifId) {
                root.removePopup(i, false);
                return;
            }
        }
    }

    function clearHistory() {
        root.history = [];
    }

    // History rows are plain data, and a ListView hands the delegates of a
    // JS-array model a *converted copy* of each element -- object identity is
    // lost (probed 2026-10-19: `modelData === history[0]` is false). So removal
    // matches on the notification's own identity fields, never on the object.
    function removeHistory(notifId, timestamp) {
        root.history = root.history.filter(e => e.notifId !== notifId || e.timestamp !== timestamp);
    }
}
