// ActiveWindow.qml — Current focused window title
//
// Shows the current focused toplevel's title, or "Desktop" if none.
// Uses m3onSurfaceVariant color, elided if too long.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property var colors
    
    implicitHeight: 28

    // Window title — fallback to "Desktop" when no window is focused
    // or when the focused workspace has no windows (matches celestia behavior)
    readonly property string windowTitle: {
        try {
            const at = Hyprland.activeToplevel
            const fw = Hyprland.focusedWorkspace
            if (!at || !fw) return "Desktop"
            const onFocusedWs = at.workspace?.id === fw.id
            const hasWindows = (fw.toplevels?.values?.length ?? 0) > 0
            const title = (onFocusedWs && hasWindows) ? at.title : null
            return title || "Desktop"
        } catch (e) {
            return "Desktop"
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right

        text: root.windowTitle
        color: colors.m3.on_surface_variant
        font.pixelSize: 13
        font.family: "Inter"
        font.weight: Font.Medium

        elide: Text.ElideRight
        horizontalAlignment: Text.AlignLeft
    }
}
