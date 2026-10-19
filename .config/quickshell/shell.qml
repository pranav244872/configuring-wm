//@ pragma IconTheme Papirus
// ~/.config/quickshell/shell.qml
//
// Our own UI, built with quickshell (see shell.md).
//   bar  - a floating top bar: workspace indicator + clock
//   osd  - a bottom-centre pill reporting volume and brightness
//   shot - screenshot utility: capture, annotate, save/copy
//   cal  - desktop month calendar (background layer, click-through)
//   notif - notification daemon + toasts (our shell owns the bus name)
//   wall - the wallpaper itself (background layer) + the carousel picker
//   cp   - desktop CP tracker card (background layer, draggable; built by
//          another agent, see references/notes/cp-tracker.md)
//
//   run:  qs -n (single instance; autostarted at login, see hypr autostart)
//   stop: qs -k
//
// Autostarted by Hyprland; SUPER + SHIFT + O restarts it if ever killed.

import QtQuick
import Quickshell
import qs.modules.osd
import qs.modules.bar
import qs.modules.launcher
import qs.modules.powermenu
import qs.modules.dashboard
import qs.modules.screenshot
import qs.modules.calendar
import qs.modules.cp_tracker
import qs.modules.lock
import qs.modules.notifications
import qs.modules.wallpaper

ShellRoot {
    TopBar {}
    OsdHost {}
    LauncherWindow {}
    PowerMenuHost {}
    DashboardHost {}
    // Before the calendar on purpose: the wallpaper is the lowest of the two
    // background-layer surfaces, and creation order decides their stacking.
    WallpaperBackground {}
    CalendarWidget {}
    CpTrackerWidget {}
    TrayMenuHost {}
    LockHost {}
    NotificationHost {}
    WallpaperHost {}
    // Last on purpose, for the same creation-order reason: the screenshot
    // editor must sit above every overlay sheet. Created before the wallpaper
    // picker, its Save/Copy toolbar was hidden behind the picker (and behind
    // the dashboard's sheet).
    ScreenshotHost {}
}