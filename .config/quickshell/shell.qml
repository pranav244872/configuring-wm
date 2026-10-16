//@ pragma IconTheme Papirus
// ~/.config/quickshell/shell.qml
//
// Our own UI, built with quickshell (see shell.md).
//   bar  - a floating top bar: workspace indicator + clock
//   osd  - a bottom-centre pill reporting volume and brightness
//   shot - screenshot utility: capture, annotate, save/copy
//   cal  - desktop month calendar (background layer, click-through)
//
//   run:  qs            (this file is quickshell's 'default' config)
//   stop: qs -c default kill
//
// Nothing autostarts it; start it from the Hyprland keybind (SUPER + SHIFT + O).

import QtQuick
import Quickshell
import qs.modules.osd
import qs.modules.bar
import qs.modules.launcher
import qs.modules.screenshot
import qs.modules.calendar

ShellRoot {
    TopBar {}
    OsdHost {}
    LauncherWindow {}
    ScreenshotHost {}
    CalendarWidget {}
}