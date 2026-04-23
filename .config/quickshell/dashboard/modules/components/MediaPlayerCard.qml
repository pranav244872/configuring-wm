// MediaPlayerCard.qml — MPRIS player controls
//
// Shows album art, track info, playback controls, volume slider.
// Uses Quickshell.Services.Mpris (available in 0.2.1).

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root

    required property var colors
    color: "transparent"
    radius: 16

    readonly property var availablePlayers: Mpris.players.values
    readonly property MprisPlayer player: {
        for (let i = 0; i < availablePlayers.length; i++) {
            if (availablePlayers[i].playbackState === MprisPlaybackState.Playing) {
                return availablePlayers[i]
            }
        }
        for (let i = 0; i < availablePlayers.length; i++) {
            if (availablePlayers[i].canControl && availablePlayers[i].canPlay) {
                return availablePlayers[i]
            }
        }
        return availablePlayers.length > 0 ? availablePlayers[0] : null
    }

    Timer {
        interval: 1000
        running: root.player && root.player.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {
            if (root.player) {
                root.player.positionChanged()
            }
        }
    }

    // Helper for formatting time into (HH:)MM:SS
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds)) return "0:00"
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        const s = Math.floor(seconds % 60)
        if (h > 0) {
            return h + ":" + String(m).padStart(2, '0') + ":" + String(s).padStart(2, '0')
        }
        return m + ":" + String(s).padStart(2, '0')
    }

    Item {
        anchors.fill: parent

        // No media state
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: root.player === null

            Text {
                text: "graphic_eq"
                color: root.colors.m3.on_surface_variant
                font.pixelSize: 64
                font.family: "Material Icons Round"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "No media playing"
                color: root.colors.m3.on_surface_variant
                font.pixelSize: 16
                font.family: "Inter"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Active player layout matching DMS
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            visible: root.player !== null

            // 1. Large centered Album Art
            Item {
                width: parent.width
                height: 200

                Rectangle {
                    width: Math.min(parent.width * 0.8, parent.height * 0.9)
                    height: width
                    radius: 20
                    anchors.centerIn: parent
                    color: root.colors.m3.surface_container_high

                    // Mask for the image corner radius
                    Rectangle {
                        id: imageMask
                        anchors.fill: parent
                        radius: 20
                        color: "black"
                        visible: false
                    }

                    Image {
                        id: img
                        anchors.fill: parent
                        source: root.player?.trackArtUrl || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: img
                        maskEnabled: true
                        maskSource: imageMask
                        visible: root.player && root.player.trackArtUrl && root.player.trackArtUrl !== ""
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "album"
                        color: root.colors.m3.on_surface_variant
                        font.pixelSize: 64
                        font.family: "Material Icons Round"
                        visible: root.player === null || root.player.trackArtUrl === undefined || root.player.trackArtUrl === ""
                    }
                }
            }

            // 2. Track Info (Centered)
            Column {
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    text: root.player?.trackTitle || "Unknown Track"
                    color: root.colors.m3.on_surface
                    font.pixelSize: 22
                    font.family: "Inter"
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                Text {
                    width: parent.width
                    text: root.player?.trackArtist || "Unknown Artist"
                    color: root.colors.m3.on_surface_variant
                    font.pixelSize: 14
                    font.family: "Inter"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.player?.trackAlbum || ""
                    color: root.colors.m3.on_surface_variant
                    font.pixelSize: 12
                    font.family: "Inter"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }

            // 3. Spacer to push controls to bottom
            Item {
                width: parent.width
                height: 1
                Layout.fillHeight: true
            }

            // 4. Seekbar
            Column {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: root.colors.m3.surface_variant
                    clip: true

                    Rectangle {
                        height: parent.height
                        radius: 3
                        color: root.colors.m3.primary
                        width: {
                            const pos = root.player?.position || 0
                            const len = root.player?.length || 1
                            return parent.width * Math.max(0, Math.min(1, pos / len))
                        }

                        Behavior on width {
                            NumberAnimation { duration: 1000 }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: root.formatTime(root.player?.position || 0)
                        color: root.colors.m3.on_surface_variant
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font Mono"
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.formatTime(root.player?.length || 0)
                        color: root.colors.m3.on_surface_variant
                        font.pixelSize: 11
                        font.family: "JetBrainsMono Nerd Font Mono"
                    }
                }
            }

            // 5. Playback Controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Previous
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: "transparent"
                    opacity: (root.player && root.player.canGoPrevious) ? 1.0 : 0.4

                    Text {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        color: root.colors.m3.on_surface
                        font.pixelSize: 28
                        font.family: "Material Icons Round"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (root.player && root.player.canGoPrevious) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { if (root.player && root.player.canGoPrevious) root.player.previous() }
                    }
                }

                // Play/Pause
                Rectangle {
                    width: 64
                    height: 64
                    radius: 32
                    color: root.colors.m3.primary

                    Text {
                        anchors.centerIn: parent
                        text: root.player && root.player.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                        color: root.colors.m3.on_primary
                        font.pixelSize: 36
                        font.family: "Material Icons Round"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (root.player) root.player.togglePlaying() }
                    }
                }

                // Next
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: "transparent"
                    opacity: (root.player && root.player.canGoNext) ? 1.0 : 0.4

                    Text {
                        anchors.centerIn: parent
                        text: "skip_next"
                        color: root.colors.m3.on_surface
                        font.pixelSize: 28
                        font.family: "Material Icons Round"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (root.player && root.player.canGoNext) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: { if (root.player && root.player.canGoNext) root.player.next() }
                    }
                }
            }
        }
    }
}
