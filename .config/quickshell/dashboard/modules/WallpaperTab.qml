// WallpaperTab.qml — Wallpaper browser tab for dashboard
//
// Embeds the wallpaper carousel + search bar from the wallpaper shell.
// Full carousel with PathView, search filtering, and apply.

import QtQuick
import "./components"

Item {
    id: root

    required property var colors
    signal close()

    Column {
        anchors.fill: parent
        spacing: 12

        WallpaperCarousel {
            id: carousel
            width: parent.width
            height: parent.height - searchBar.height - parent.spacing
            filterText: searchBar.text
            colors: root.colors
            onApplied: root.close()
        }

        SearchBar {
            id: searchBar
            width: parent.width
            colors: root.colors
            onAcceptPressed: carousel.applyWallpaper()
            onEscapePressed: root.close()
            onLeftPressed: carousel.goLeft()
            onRightPressed: carousel.goRight()
        }
    }
}
