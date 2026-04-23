pragma ComponentBehavior: Bound

// Bar.qml — Main bar layout
//
// Caelestia-inspired horizontal bar:
//   OsIcon → Workspaces → ActiveWindow (fills center-left) → Clock (center) → [Tray] → StatusBar
//
// Changes from original:
//   - NotificationBell removed (notifications accessible via side panel)
//   - StatusIcons replaced by StatusBar (wifi/bt/power cluster + battery)
//   - StatusBar cluster click opens side panel (IPC "sidepanel")

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "./components"
import "../../../qs/services"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 40

    margins {
        top: 0
        left: 0
        right: 0
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.m3.surface

        // ── Left: OsIcon + Workspaces ───────────────────────────────────────
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            OsIcon {
                colors: Colors
            }

            Workspaces {
                colors: Colors
            }
        }

        // ── Center: Clock ───────────────────────────────────────────────────
        Clock {
            id: centerClock
            anchors.centerIn: parent
            colors: Colors
        }

        // ── Right: Tray + StatusBar ─────────────────────────────────────────
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Tray {
                colors: Colors
            }

            StatusBar {
                colors: Colors
            }
        }

        // ── Active window title (left ↔ clock) ───────────────────────────────
        ActiveWindow {
            anchors.left: leftSection.right
            anchors.right: centerClock.left
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            colors: Colors
        }
    }
}
