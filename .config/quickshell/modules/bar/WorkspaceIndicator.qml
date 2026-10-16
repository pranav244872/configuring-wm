// Workspaces 1..5 persistent + active/occupied extras. end-4 style: one pill
// behind the numbers that glides to the active slot, trailing-stretching
// between old and new while it moves (slot 26, pill 22).
import QtQuick
import Quickshell.Hyprland
import qs.modules
import qs.modules.widgets

Item {
    id: root

    property int activeWsIdOverride: -1
    readonly property int activeWsId: activeWsIdOverride > 0 ? activeWsIdOverride : (Hyprland.focusedWorkspace?.id ?? Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1)

    readonly property var wsList: {
        const list = [1, 2, 3, 4, 5];
        const extra = [];
        if (root.activeWsId > 5)
            extra.push(root.activeWsId);
        for (const w of Hyprland.workspaces?.values ?? []) {
            if (w.id > 5 && (w.toplevels?.values?.length ?? 0) > 0 && !extra.includes(w.id))
                extra.push(w.id);
        }
        extra.sort((a, b) => a - b);
        return list.concat(extra);
    }

    readonly property int activeIndex: Math.max(0, root.wsList.indexOf(root.activeWsId))

    function occupied(id) {
        return (Hyprland.workspaces?.values?.find(w => w.id === id)?.toplevels?.values?.length ?? 0) > 0;
    }

    function focusWorkspace(id) {
        // Our compositor runs a Lua config: plain "workspace N" dispatchers get
        // wrapped into hl.dispatch(workspace N) and fail, and usingLua reports
        // false on our fork, so send the Lua form.
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    // End-4 trail: leading index snaps to the active slot, the trailing one
    // lags behind so the pill stretches between old and new while it glides.
    property real pillLead: root.activeIndex
    property real pillTrail: root.activeIndex

    Behavior on pillLead {
        NumberAnimation {
            duration: 40
            easing.type: Easing.OutSine
        }
    }
    Behavior on pillTrail {
        NumberAnimation {
            duration: Theme.animation.moveDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.animation.curveMove
        }
    }

    // Pill geometry: circle (2px inset) when settled, capsule spanning the
    // lead/trail distance mid-switch
    readonly property int inset: (Theme.bar.chipSize - Theme.bar.pillSize) / 2
    readonly property real pillX: Math.min(root.pillLead, root.pillTrail) * Theme.bar.chipSize + root.inset
    readonly property real pillW: Math.abs(root.pillLead - root.pillTrail) * Theme.bar.chipSize + Theme.bar.pillSize

    implicitWidth: root.wsList.length * Theme.bar.chipSize
    implicitHeight: Theme.bar.chipSize

    // The moving block sits behind all the numbers (square, Chaldea frame)
    Rectangle {
        id: pill
        y: root.inset
        height: Theme.bar.pillSize
        radius: 0
        color: Theme.colors.primary

        x: root.pillX
        width: root.pillW

        Behavior on x {
            NumberAnimation {
                duration: Theme.animation.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveMove
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Theme.animation.moveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveMove
            }
        }
    }

    Repeater {
        model: root.wsList

        delegate: MouseArea {
            id: slotMa
            required property int index
            required property int modelData

            readonly property int wsId: modelData
            readonly property bool focused: root.activeWsId === wsId
            readonly property bool occupied: root.occupied(wsId)

            x: index * Theme.bar.chipSize
            y: 0
            width: Theme.bar.chipSize
            height: Theme.bar.chipSize
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.focusWorkspace(wsId)

            // Hover state layer; the active slot already has the block
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 0
                color: Theme.colors.stateHover
                visible: parent.containsMouse && !parent.focused
            }

            StyledText {
                anchors.centerIn: parent
                text: String(parent.wsId)

                // Digit re-colours exactly as the pill covers it: end-4 does this
                // with a colourizer mask, we just track the pill span (no shader).
                // The band is narrow, so the text flips just ahead of the pill edge.
                readonly property real pillL: root.pillX
                readonly property real pillR: root.pillX + root.pillW
                readonly property real centreX: parent.index * Theme.bar.chipSize + Theme.bar.chipSize / 2
                readonly property real dockL: centreX - Theme.bar.dockHalf
                readonly property real dockR: centreX + Theme.bar.dockHalf
                readonly property real coverage: Math.max(0, Math.min(pillR, dockR) - Math.max(pillL, dockL)) / (2 * Theme.bar.dockHalf)
                readonly property color baseColor: parent.occupied ? Theme.colors.fgLayer1
                                                                   : ColorUtils.transparentize(Theme.colors.fgLayer1, 0.60)

                color: ColorUtils.mix(baseColor, Theme.colors.fgPrimary, coverage)
                font.pixelSize: Theme.font.size.xs
                font.weight: parent.focused ? Font.Black : (parent.occupied ? Font.Bold : Font.DemiBold)
            }
        }
    }
}
