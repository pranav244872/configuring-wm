// NotificationCard.qml — Notification display card (popup + history)
//
// FIXES:
//   - Close button (×) now reliably fires above the card-level MouseArea (z: 1 on content)
//   - Actions use invoke() only for live popup QObjects (history cards are read-only)
//   - App icon loading covers all source formats: URL, absolute path, icon name
//   - History mode: X button calls NotifService.removeFromHistory() instead of removePopup()
//   - Card-level click dismisses popup (not history) to avoid accidental removal

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../qs/services"

Item {
    id: root

    required property int index
    required property var modelData

    // forceRounded: true when inside history list (always round bottom corners)
    // isHistory: true disables card-level click-to-dismiss
    property bool forceRounded: false
    property bool isHistory: false

    readonly property bool isLast: forceRounded || (ListView.view && index === ListView.view.count - 1)
    readonly property bool valid: modelData !== null && modelData !== undefined

    // Can we call invoke() on actions? Only live QObjects have it.
    readonly property bool hasLiveActions: valid
        && modelData.actions
        && modelData.actions.length > 0
        && typeof modelData.actions[0].invoke === "function"

    width: ListView.view ? ListView.view.width : 340
    implicitHeight: valid ? (contentColumn.implicitHeight + 24) : 0
    visible: valid

    // ── Background ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Colors.m3.surface_container
        radius: isLast ? 16 : 0

        // Square the top corners when we have a radius (bottom-only rounding)
        Rectangle {
            width: parent.width
            height: parent.radius
            color: parent.color
            anchors.top: parent.top
            visible: isLast
        }
    }

    // ── Card-level dismiss (popup only, not history) ─────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: 0
        onClicked: {
            if (!root.isHistory && root.valid) {
                NotifService.removePopup(root.modelData)
            }
        }
    }

    // ── Content ──────────────────────────────────────────────────────────────
    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8
        z: 1   // Above card-level MouseArea — ensures close/action buttons register clicks

        // ── Header row: icon + app name + time + close ─────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // App icon
            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20

                readonly property string resolvedIcon: {
                    if (!root.valid) return ""
                    const raw = root.modelData.iconName || root.modelData.icon || ""
                    if (!raw) return ""
                    if (raw.startsWith("http://") || raw.startsWith("https://") || raw.startsWith("file://")) return raw
                    if (raw.startsWith("/")) return "file://" + raw
                    return "image://icon/" + raw
                }

                IconImage {
                    anchors.fill: parent
                    source: parent.resolvedIcon
                    visible: parent.resolvedIcon !== ""
                    smooth: true
                }

                // Fallback: first letter of app name
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Colors.m3.primary_container
                    visible: parent.resolvedIcon === ""

                    Text {
                        anchors.centerIn: parent
                        text: root.valid ? (root.modelData.appName || "?").charAt(0).toUpperCase() : "?"
                        color: Colors.m3.on_primary_container
                        font.family: "Inter"
                        font.weight: Font.Bold
                        font.pixelSize: 11
                    }
                }
            }

            // App name
            Text {
                Layout.fillWidth: true
                text: root.valid ? (root.modelData.appName || "Notification") : ""
                color: Colors.m3.on_surface_variant
                font.family: "Inter"
                font.weight: Font.Medium
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            // Timestamp
            Text {
                text: {
                    if (!root.valid) return ""
                    const t = root.modelData.time instanceof Date
                        ? root.modelData.time
                        : new Date()
                    return Qt.formatTime(t, "hh:mm A")
                }
                color: Colors.m3.outline
                font.family: "Inter"
                font.pixelSize: 11
            }

            // Close / dismiss button
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                color: closeArea.containsMouse ? Colors.m3.error_container : "transparent"
                radius: 10

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeArea.containsMouse ? Colors.m3.on_error_container : Colors.m3.outline
                    font.family: "Inter"
                    font.weight: Font.Bold
                    font.pixelSize: 16
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Propagate composed events so parent MouseArea doesn't steal
                    propagateComposedEvents: false
                    onClicked: mouse => {
                        mouse.accepted = true
                        if (!root.valid) return
                        if (root.isHistory) {
                            NotifService.removeFromHistory(root.modelData.id)
                        } else {
                            NotifService.removePopup(root.modelData)
                        }
                    }
                }
            }
        }

        // ── Summary / title ─────────────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: root.valid ? (root.modelData.summary || "") : ""
            color: Colors.m3.on_surface
            font.family: "Inter"
            font.weight: Font.Bold
            font.pixelSize: 14
            elide: Text.ElideRight
            visible: text !== ""
        }

        // ── Body ────────────────────────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: root.valid ? (root.modelData.body || "") : ""
            color: Colors.m3.on_surface_variant
            font.family: "Inter"
            font.pixelSize: 13
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            visible: text !== ""
        }

        // ── Actions (live popups only) ───────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.hasLiveActions

            Repeater {
                model: root.hasLiveActions ? root.modelData.actions : []

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 16
                    color: actionArea.containsMouse ? Colors.m3.primary : Colors.m3.surface_container_highest

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        color: actionArea.containsMouse ? Colors.m3.on_primary : Colors.m3.on_surface
                        font.family: "Inter"
                        font.weight: Font.Medium
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof modelData.invoke === "function") {
                                modelData.invoke()
                            }
                            NotifService.removePopup(root.modelData)
                        }
                    }
                }
            }
        }
    }
}
