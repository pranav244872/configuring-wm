pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Audio.qml — Event-driven audio service using PipeWire
//
// Provides instant volume/mute updates via PipeWire's native event system.
// No polling, no Process objects. Volume changes from ANY source
// (keybinds, pavucontrol, other apps) are reflected immediately.

Singleton {
    id: root

    // ── Public API ───────────────────────────────────────────────────────────
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property int sinkVolume: sink?.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool sinkMuted: sink?.audio?.muted ?? false

    readonly property int sourceVolume: source?.audio ? Math.round(source.audio.volume * 100) : 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

    // ── Volume control functions ─────────────────────────────────────────────
    function setVolume(v) {
        if (sink?.audio) {
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function setSinkMuted(muted) {
        if (sink?.audio) {
            sink.audio.muted = muted
        }
    }

    function toggleSinkMute() {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted
        }
    }

    function setMicVolume(v) {
        if (source?.audio) {
            source.audio.volume = Math.max(0, Math.min(1, v))
        }
    }

    function setSourceMuted(muted) {
        if (source?.audio) {
            source.audio.muted = muted
        }
    }

    function toggleSourceMute() {
        if (source?.audio) {
            source.audio.muted = !source.audio.muted
        }
    }

    // ── PipeWire object tracker (REQUIRED for properties to update) ──────────
    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink,
            Pipewire.defaultAudioSource
        ]
    }
}
