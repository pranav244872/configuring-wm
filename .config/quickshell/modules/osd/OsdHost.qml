// OSD host: a bottom-centre pill that reports volume / brightness changes.
//
// Integration follows end-4/dots-hyprland:
//
//   volume      reactive - we watch the default PipeWire sink, so *any* change
//               shows the pill (XF86Audio* binds, pavucontrol, pactl, ...).
//               The *value* is read with wpctl, because PwNode's volume is only
//               a factor over the sink's base volume (it exceeds 1.0 and isn't
//               what the user hears). One tiny process, only on change.
//   brightness  IPC - the keybind changes brightness and then calls us:
//               XF86MonBrightnessUp -> brightnessctl ... ; qs ipc call osd brightness
//
// Nothing polls.
//
// API notes (verified against the quickshell 0.3.2 source, see gotchas.md):
//   * PanelWindow has no `opacity` / `y` -> animate the child item instead.
//   * IpcHandler functions must declare their types or they are not registered.
//   * Process stdout is a parser object (StdioCollector), not a string property.
//   * PipeWire volume/muted live on `node.audio` and are only valid once the
//     node is bound through a PwObjectTracker.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules
import qs.modules.widgets
import qs.modules.osd

PanelWindow {
    id: host

    property string label: ""
    property string glyph: ""
    property real value: 0
    property bool muted: false
    property bool showing: false

    // ---- mouse control state ----
    property bool dragging: false      // the user is dragging the slider
    property bool pointerOn: false     // pointer is on the slider (hover or drag)
    readonly property bool interactive: label !== ""

    // No horizontal anchor = the layer-shell spec centers the surface.
    anchors {
        bottom: true
    }

    margins {
        bottom: Theme.sizes.osdBottom
    }

    implicitWidth: Theme.sizes.osdWidth
    implicitHeight: Theme.sizes.osdHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    // Clicks must pass through while the pill is hidden.
    //
    // The window is always on screen at a fixed size, and `opacity: 0` does
    // NOT stop Qt delivering input - so without this the invisible pill still
    // sits over the bottom-centre of the screen and its MouseArea fires
    // `userMoved()`, which both re-shows the OSD *and* writes a new
    // volume/brightness. A stray click near the bottom edge changed the volume.
    //
    // `mask` is quickshell's clickthrough region (windowinterface.hpp): with
    // `Combine` the region is what stays clickable, with `Xor` it is what
    // becomes *un*clickable. `content` fills the window, so Xor leaves an
    // empty clickable area - i.e. everything falls through to the window
    // below. Rendering is unaffected either way.
    mask: Region {
        item: content
        intersection: host.showing ? Intersection.Combine : Intersection.Xor
    }

    // Fade + a small rise. PanelWindow itself can't be animated, so this wrapper
    // carries the motion and the pill lives inside it.
    Item {
        id: content

        anchors.fill: parent

        opacity: host.showing ? 1 : 0
        y: host.showing ? 0 : 12

        // One animation object, with duration/curve bound to `showing`: a
        // Behavior cannot swap its animation while it is running (Qt warns
        // "Cannot change the animation assigned to a Behavior").
        Behavior on opacity {
            NumberAnimation {
                duration: host.showing ? Theme.animation.enterDuration
                                       : Theme.animation.exitDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: host.showing ? Theme.animation.curveOut
                                                 : Theme.animation.curveIn
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: host.showing ? Theme.animation.enterDuration
                                       : Theme.animation.exitDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: host.showing ? Theme.animation.curveOut
                                                 : Theme.animation.curveIn
            }
        }

        OsdIndicator {
            id: indicator
            anchors.centerIn: parent
            label: host.label
            glyph: host.glyph
            value: host.value
            muted: host.muted
            locked: !host.interactive

            onPointerOnSliderChanged: {
                host.pointerOn = indicator.pointerOnSlider;
                if (indicator.pointerOnSlider)
                    host.keepAlive();
            }
            onSliderValueChanged: newValue => host.userMoved(newValue)
            onSliderDragFinished: host.userReleased()
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: if (!host.dragging && !host.pointerOn)
                          host.showing = false
    }

    function keepAlive() {
        if (showing)
            hideTimer.restart();
    }

    // ---- volume (reactive trigger, wpctl for the number) -----------------
    property var sink: Pipewire.defaultAudioSink

    // Mandatory: without this the audio properties read as 0/undefined.
    PwObjectTracker {
        objects: host.sink ? [host.sink] : []
    }

    property real nodeVolume: (sink && sink.audio) ? (sink.audio.volume ?? -1) : -1
    property bool nodeMuted: (sink && sink.audio) ? (sink.audio.muted ?? false) : false

    onNodeVolumeChanged: if (nodeVolume >= 0 && !dragging)
                              volumeProbe.running = true;
    onNodeMutedChanged: if (nodeVolume >= 0 && !dragging)
                             volumeProbe.running = true;

    Process {
        id: volumeProbe
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]

        stdout: StdioCollector {
            id: volumeOut
            onStreamFinished: host.applyVolume(volumeOut.text)
        }
    }

    property bool ready: false

    Timer {
        id: startupGuard
        interval: 1200
        running: true
        onTriggered: host.ready = true
    }

    function applyVolume(text) {
        const match = /Volume:\s*([0-9.]+)/.exec(text);
        if (!match || dragging)
            return;
        value = Math.max(0, Math.min(1, parseFloat(match[1])));
        muted = /\[MUTED\]/.test(text);
        label = muted ? "Muted" : "Volume";
        glyph = Icons.volume(value, muted);
        if (host.ready) {
            showing = true;
            hideTimer.restart();
        }
    }

    // ---- brightness (IPC from the keybind) ------------------------------
    // `brightnessctl get` returns RAW units on sysfs backlights (this laptop:
    // intel_backlight, 0..26666) and version 0.5 has no percentage mode, so we
    // scale against max_brightness ourselves and print the percentage.
    Process {
        id: brightnessProbe
        command: ["sh", "-c",
                  "b=$(brightnessctl get) || exit 1; " +
                  "m=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1); " +
                  "[ -z \"$m\" ] && m=1; " +
                  "echo $(( (b * 100 + m / 2) / m ))"]

        stdout: StdioCollector {
            id: brightnessOut
            onStreamFinished: host.applyBrightness(brightnessOut.text)
        }
    }

    function applyBrightness(text) {
        const match = /([0-9.]+)/.exec(text);
        if (!match || dragging)
            return;
        value = Math.max(0, Math.min(100, parseFloat(match[1]))) / 100;
        muted = false;
        label = "Brightness";
        glyph = Icons.brightness(value);
        showing = true;
        hideTimer.restart();
    }

    // ---- writing values the user picked by dragging --------------------
    // Volume and brightness are written with the same tools our *reads* use
    // (wpctl / brightness.sh). Writing PipeWire's node volume directly - what
    // DankMaterialShell and caelestia do - would be wrong on hardware-volume
    // devices like our headset: the node factor is not the percentage you hear.
    //
    // A drag emits ~100 position events/second, so writes are coalesced into
    // one every WRITE_INTERVAL ms, and release applies the last one at once
    // (same live/final split as DMS's sliderValueChanged/sliderDragFinished).

    readonly property int writeInterval: 50

    // Dragging the slider sets a level AND unmutes (same rule as the volume
    // keys); the release probe then confirms what actually landed.
    Process {
        id: volumeWriter
        command: ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " + Math.round(host.value * 100) + "%"]
    }

    Process {
        id: brightnessWriter
        command: ["sh", "/home/pranav/.config/hypr/scripts/brightness.sh",
                  "set", String(Math.round(host.value * 100))]
    }

    Timer {
        id: writeTimer
        interval: host.writeInterval
        onTriggered: host.writeValue()
    }

    function writeValue() {
        if (label === "Brightness")
            brightnessWriter.running = true;
        else
            volumeWriter.running = true;
    }

    // Live feedback: the UI follows the pointer immediately, the write follows
    // on the coalescing timer.
    function userMoved(newValue) {
        dragging = true;
        value = Math.max(0, Math.min(1, newValue));
        if (label === "Brightness") {
            glyph = Icons.brightness(value);
        } else {
            muted = false;
            label = "Volume";
            glyph = Icons.volume(value, false);
        }
        showing = true;
        writeTimer.restart();
    }

    function userReleased() {
        dragging = false;
        writeTimer.stop();
        writeValue();
        keepAlive();
        // Reconcile with reality: the panel quantises steps, so read back
        // what actually landed.
        if (label === "Brightness")
            brightnessProbe.running = true;
        else
            volumeProbe.running = true;
    }

    // ---- external triggers (from the Hyprland keybinds) -----------------
    IpcHandler {
        target: "osd"

        function brightness(): void {
            brightnessProbe.running = true;
        }

        // Refresh the volume readout without changing anything.
        function volume(): void {
            host.ready = true;
            volumeProbe.running = true;
        }
    }
}