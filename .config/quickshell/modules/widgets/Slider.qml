// Value slider you can drag: press anywhere to jump, drag to follow, release to
// finish. Input model copied from DankMaterialShell's DSlider (the reference
// for an interactive quickshell OSD) minus wheel support - the wheel step is
// deliberately not there, the keys already handle stepping.
//
// Two signals on purpose, like DMS:
//   sliderValueChanged  - live, fire-and-forget while dragging
//   sliderDragFinished  - the last word, for flushing any coalesced work
//
// No tooltip: the percentage already sits beside the pill, so a floating
// value bubble would only repeat it.

import QtQuick
import qs.modules

Item {
    id: root

    required property real value          // 0..1, driven from outside
    property bool interactive: true
    property color fillColor: Theme.colors.primary

    signal sliderValueChanged(real value)
    signal sliderDragFinished()

    property bool dragging: false
    readonly property bool hovered: mouse.containsMouse
    readonly property bool active: interactive && (dragging || hovered)

    readonly property real trackHeight: Theme.sizes.barThickness
    readonly property real handleSize: Theme.sizes.sliderHandle
    readonly property real ratio: Math.max(0, Math.min(1, value))

    implicitWidth: Theme.sizes.barLength
    implicitHeight: Theme.sizes.sliderSlot

    // Handle-aware mapping (DMS): the handle *centre* follows the pointer
    // instead of the handle's left edge, so the value under the cursor is
    // always the value you get.
    function ratioFromX(x) {
        const travel = Math.max(1, width - handleSize);
        return Math.max(0, Math.min(1, (x - handleSize / 2) / travel));
    }

    function commit(x) {
        if (!interactive)
            return;
        root.sliderValueChanged(ratioFromX(x));
    }

    Rectangle {                                   // track
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: Theme.colors.barTrack
    }

    Rectangle {                                   // fill
        id: fill
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        height: track.height
        width: root.ratio * track.width
        radius: height / 2
        color: root.fillColor

        // Tween external changes (keys, other tools) but never during a drag:
        // the handle tracks the pointer instantly, and an animating fill would
        // lag behind it, leaving a trail.
        Behavior on width {
            enabled: !root.dragging
            animation: Theme.animation.value.createObject(this)
        }
    }

    Rectangle {                                   // handle
        width: root.handleSize
        height: width
        radius: width / 2
        color: root.fillColor
        x: root.ratio * (track.width - width)
        y: track.y + track.height / 2 - height / 2
        scale: root.active ? 1 : 0.55
        opacity: root.active ? 1 : 0

        Behavior on scale {
            animation: Theme.animation.value.createObject(this)
        }
        Behavior on opacity {
            animation: Theme.animation.value.createObject(this)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // The slot is only as tall as the bar, so grow the grab target well past
        // it (same trick as DMS's `anchors.margins: -12`) - the pill stays tight
        // without making the slider hard to catch.
        anchors.topMargin: -Theme.sizes.sliderGrabPad
        anchors.bottomMargin: -Theme.sizes.sliderGrabPad
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        preventStealing: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPressed: event => {
            root.dragging = true;
            root.commit(event.x);
        }
        onPositionChanged: event => {
            if (pressed)
                root.commit(event.x);
        }
        onReleased: event => {
            root.commit(event.x);
            root.dragging = false;
            root.sliderDragFinished();
        }
        onCanceled: root.dragging = false
    }
}