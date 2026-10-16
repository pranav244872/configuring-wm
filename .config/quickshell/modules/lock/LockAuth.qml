// Password auth machine. Buffer goes to PAM's respond() and is cleared on
// every path; nothing secret is ever logged. Password-only: no
// fingerprint/howdy daemons.
import QtQuick
import Quickshell.Services.Pam

Item {
    id: root
    visible: false

    enum State {
        None,
        Error,
        MaxTries,
        Failed
    }

    signal flashMsg()
    signal unlocked()

    property string buffer: ""
    property int state: LockAuth.State.None
    property string lockMessage: ""
    readonly property bool busy: passwd.active

    function reset() {
        if (passwd.active)
            passwd.abort();
        root.buffer = "";
        root.state = LockAuth.State.None;
        root.lockMessage = "";
    }

    function submit() {
        if (passwd.active || root.state === LockAuth.State.MaxTries)
            return;
        if (root.buffer.length === 0)
            return;
        root.state = LockAuth.State.None;
        passwd.start();
    }

    PamContext {
        id: passwd
        config: "login"

        onPamMessage: {
            if (passwd.message.startsWith("The account is locked"))
                root.lockMessage = passwd.message;
            if (passwd.responseRequired) {
                const secret = root.buffer;
                root.buffer = "";
                passwd.respond(secret);
            }
        }

        onCompleted: (res) => {
            root.buffer = "";
            if (res === PamResult.Success) {
                root.state = LockAuth.State.None;
                root.lockMessage = "";
                root.unlocked();
                return;
            }
            if (res === PamResult.Error)
                root.state = LockAuth.State.Error;
            else if (res === PamResult.MaxTries)
                root.state = LockAuth.State.MaxTries;
            else
                root.state = LockAuth.State.Failed;
            root.flashMsg();
            stateReset.restart();
        }
    }

    Timer {
        id: stateReset
        interval: 4000
        onTriggered: {
            if (root.state !== LockAuth.State.MaxTries)
                root.state = LockAuth.State.None;
        }
    }
}
