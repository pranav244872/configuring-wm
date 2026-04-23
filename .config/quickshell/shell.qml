//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import "bar/modules/bar" as Bar
import "dashboard/modules" as Dashboard
import "launcher/modules" as Launcher
import "lockscreen/modules/lock" as Lock
import "bar/modules/notifications" as Notifications
import "side_panel/modules" as Side

ShellRoot {
    settings.watchFiles: true
    Bar.Bar {}

    Dashboard.DashboardWindow {
        id: dashboardWindow
    }

    Launcher.LauncherWindow {
        id: launcherWindow
    }

    Lock.Lock {
        id: lockscreen
    }

    // Live popup toasts — stays independent of the side panel
    Notifications.NotificationPopup {
        id: notificationPopup
    }

    // Control center + notification history (replaces NotificationCenter)
    Side.ControlCenterWindow {
        id: sidePanel
    }

    // Screenshot selection menu
    Side.ScreenshotMenu {
        id: screenshotMenu
    }

    // Network menu (Wi-Fi/Bluetooth)
    Side.NetworkMenu {
        id: networkMenu
    }

    // Night light temperature control
    Side.NightLightMenu {
        id: nightLightMenu
    }

    // ── IPC handlers ──────────────────────────────────────────────────────────

    IpcHandler {
        target: "launcher"
        function toggle() { launcherWindow.toggle() }
        function open()   { launcherWindow.open() }
        function close()  { launcherWindow.close() }
    }

    IpcHandler {
        target: "dashboard"
        function toggle() { dashboardWindow.toggle() }
        function open()   { dashboardWindow.open() }
        function close()  { dashboardWindow.close() }
    }

    IpcHandler {
        target: "lock"
        function toggle() { lockscreen.lock.locked = !lockscreen.lock.locked }
        function open()   { lockscreen.lock.locked = true }
        function close()  { lockscreen.lock.unlock() }
    }

    // "notifications" IPC now opens the side panel
    // (keeps backward compat with existing keybinds)
    IpcHandler {
        target: "notifications"
        function toggle() { sidePanel.toggle() }
        function open()   { sidePanel.open() }
        function close()  { sidePanel.close() }
    }

    // Also expose as "sidepanel" for the bar's status cluster click
    IpcHandler {
        target: "sidepanel"
        function toggle() { sidePanel.toggle() }
        function open()   { sidePanel.open() }
        function close()  { sidePanel.close() }
    }
}
