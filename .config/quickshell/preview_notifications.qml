// Notifications bench: the card in every state it can be drawn in, the two bar
// states of the DND button, and the dashboard section with history. The live
// toast stack itself is a separate overlay surface (it can't be captured by
// grabToImage), so it is verified live -- see notes/notifications.md.
// Saves preview_notifications.png
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules
import qs.modules.widgets
import qs.modules.bar
import qs.modules.dashboard
import qs.modules.notifications

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#2b3134"
        implicitWidth: 780
        implicitHeight: 1000

        // The bench paints the DND bar state by flipping the singleton. This
        // guards the write-back so a screenshot never edits the real setting.
        Component.onCompleted: NotificationService.hydrating = true
        Component.onDestruction: NotificationService.hydrating = false

        ColumnLayout {
            id: scene
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            StyledText {
                text: "NOTIFICATION CARD"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            // Normal: app + title + body, countdown two thirds through.
            NotificationCard {
                app: "Firefox"
                appIcon: "firefox"
                summary: "Download complete"
                body: "ubuntu-24.04-desktop-amd64.iso — 5.9 GB"
                urgency: 1
                progress: 0.66
            }

            // Critical: alarm colour, long body, no clock (sticky).
            NotificationCard {
                app: "systemd"
                summary: "Battery critically low"
                body: "3% remaining. Plug in now — the session suspends at 2% unless a charger appears."
                urgency: 2
                progress: -1
            }

            // Low: quiet accent, avatar image instead of a themed icon.
            NotificationCard {
                app: "Spotify"
                image: Quickshell.iconPath("audio-x-generic", true)
                summary: "Now playing"
                body: "Aphex Twin — Xtal"
                urgency: 0
                progress: 0.25
            }

            // No icon at all: the bell fallback.
            NotificationCard {
                app: "notify-send"
                summary: "Heads up"
                body: "No icon, no avatar, no action."
                urgency: 1
                progress: 1.0
            }

            // The live bar island: clean while DND is off, showing the bell in
            // the second screenshot (the bench only paints the state).
            BarIsland {
                Layout.alignment: Qt.AlignHCenter
                activeWsIdOverride: 2
            }

            StyledText {
                text: "DASHBOARD SECTION"
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            // History: what the sheet shows after the toasts above have come
            // and gone (plain data behind each row).
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 240

                NotificationsSection {
                    anchors.left: parent.left
                    width: 334
                    height: parent.height
                }
            }
        }

        // Two screenshots: DND off (bar clean) then DND on (bell shows).
        Timer {
            interval: 700
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_notifications saved:", r.saveToFile("/tmp/opencode/preview_notifications.png"));
                NotificationService.history = [
                    { notifId: 3, app: "Firefox", appIcon: "firefox", summary: "Download complete",
                      body: "ubuntu-24.04-desktop-amd64.iso — 5.9 GB", image: "", urgency: 1,
                      expireTimeout: 0, timestamp: Date.now() - 120000 },
                    { notifId: 2, app: "systemd", appIcon: "", summary: "Battery critically low",
                      body: "3% remaining.", image: "", urgency: 2, expireTimeout: 0,
                      timestamp: Date.now() - 600000 },
                    { notifId: 1, app: "Spotify", appIcon: "", summary: "Now playing",
                      body: "Aphex Twin — Xtal", image: Quickshell.iconPath("audio-x-generic", true),
                      urgency: 0, expireTimeout: 0, timestamp: Date.now() - 900000 }
                ];
                NotificationService.doNotDisturb = true;
                Qt.callLater(function () {
                    scene.grabToImage(function (r2) {
                        console.log("preview_notifications_dnd saved:", r2.saveToFile("/tmp/opencode/preview_notifications_dnd.png"));
                        Qt.quit();
                    });
                });
            })
        }
    }
}
