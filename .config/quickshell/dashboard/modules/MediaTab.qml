// MediaTab.qml — Full media player tab
//
// Shows MPRIS player controls with album art, track info, playback buttons.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "./components"

Item {
    id: root

    required property var colors
    signal close()

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

    MediaPlayerCard {
        anchors.fill: parent
        colors: root.colors
    }
}
