// Notification host: the toast stack.
//
// A full-screen overlay whose only interactive area is the cards themselves
// (mask), so a click anywhere else falls through to whatever is underneath.
// Toasts stack top-right, clear of the bar: the placement every reference shell
// uses with a top bar.
//
// The delegate ("slot") owns the countdown, not the card -- the card is shared
// with the history list, where a clock means nothing. Slots survive model
// changes because the model is a ListModel and we only insert one row at a
// time; reassigning a JS-array model would rebuild every delegate and with it
// every countdown and hover pause.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules
import qs.modules.notifications

PanelWindow {
    id: host

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Mapped only while a toast is up: an always-mapped overlay above
    // fullscreen windows costs a layer surface for nothing.
    visible: NotificationService.popups.count > 0

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Never take focus: a toast must not interrupt what you are typing.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: stack
    }

    Column {
        id: stack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.notifications.topOffset
        anchors.rightMargin: Theme.notifications.sideOffset
        width: Theme.notifications.width
        spacing: Theme.notifications.gap

        Repeater {
            model: NotificationService.popups

            delegate: Item {
                id: slot
                required property int index
                required property string app
                required property string appIcon
                required property string summary
                required property string body
                required property string image
                required property int urgency
                required property real expireTimeout

                width: stack.width
                implicitHeight: card.implicitHeight

                // 0 == sticky: critical notifications stay until dismissed.
                readonly property real lifetime: NotificationService.durationFor(slot.urgency,
                                                                                slot.expireTimeout)

                property real remainingLifetime: 1.0
                readonly property bool ticking: slot.lifetime > 0 && !card.hovered

                // Fade in. Nothing animates out: a dismissal has to be immediate
                // or the stack would hold a gap where the card used to be.
                property bool entered: false
                opacity: slot.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animation.enterDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.animation.curveOut
                    }
                }

                Component.onCompleted: slot.entered = true

                // A client rewriting this notification in place (replaces_id)
                // rewrites the row, and new text deserves a full look: the
                // countdown starts over instead of running out the clock the
                // superseded text was already most of the way through.
                onSummaryChanged: slot.remainingLifetime = 1.0
                onBodyChanged: slot.remainingLifetime = 1.0
                onImageChanged: slot.remainingLifetime = 1.0

                Timer {
                    interval: Theme.notifications.tick
                    repeat: true
                    running: slot.ticking
                    onTriggered: {
                        if (slot.lifetime <= 0)
                            return;
                        slot.remainingLifetime -= Theme.notifications.tick / slot.lifetime;
                        if (slot.remainingLifetime <= 0) {
                            slot.remainingLifetime = 0;
                            NotificationService.expirePopup(slot.index);
                        }
                    }
                }

                NotificationCard {
                    id: card
                    anchors.right: parent.right
                    width: parent.width

                    app: slot.app
                    appIcon: slot.appIcon
                    summary: slot.summary
                    body: slot.body
                    image: slot.image
                    urgency: slot.urgency
                    progress: slot.remainingLifetime

                    onCloseRequested: NotificationService.dismissPopup(slot.index)
                    onCardClicked: NotificationService.invokeDefault(slot.index)
                }
            }
        }
    }

    IpcHandler {
        target: "notifications"

        function dismissAll(): void {
            NotificationService.dismissAll();
        }

        // The newest toast, i.e. the one being read.
        function dismissOne(): void {
            NotificationService.dismissNewest();
        }

        function invokeLast(): void {
            NotificationService.invokeLast();
        }

        function clearHistory(): void {
            NotificationService.clearHistory();
        }

        function toggleDnd(): void {
            NotificationService.toggleDnd();
        }

        function setDnd(value: bool): void {
            NotificationService.setDnd(value);
        }

        function dndState(): bool {
            return NotificationService.doNotDisturb;
        }

        // Counts exist so scripts (and our live verification) can assert state.
        function count(): int {
            return NotificationService.popups.count;
        }

        function historyCount(): int {
            return NotificationService.history.length;
        }
    }
}
