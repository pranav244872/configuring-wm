//@ pragma IconTheme Papirus
// ~/.config/quickshell/shell.qml
//
// Our own UI, built with quickshell (see shell.md).
//   bar  - a floating top bar: workspace indicator + clock
//   osd  - a bottom-centre pill reporting volume and brightness
//   shot - screenshot utility: capture, annotate, save/copy
//   cal  - desktop month calendar (background layer, click-through)
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
import qs.modules.screenshot
import qs.modules.calendar
import qs.modules.lock

ShellRoot {
    TopBar {}
    OsdHost {}
    LauncherWindow {}
    ScreenshotHost {}
    CalendarWidget {}
    TrayMenuHost {}
    LockHost {}
}