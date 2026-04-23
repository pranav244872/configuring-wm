// WallpaperCarousel.qml — Horizontal wallpaper carousel with navigation
//
// Adapted from the wallpaper shell for use in the dashboard tab.
// PathView carousel with z-ordering, search filtering, and apply.

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "./"

Rectangle {
    id: root

    color: "transparent"

    property string filterText: ""
    required property var colors

    signal applied(string path)

    readonly property string statePath: Quickshell.env("HOME") + "/.cache/qs-wallpaper-path"
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property int itemWidth: 280
    readonly property int maxWallpapers: 9

    readonly property int numItems: {
        const maxItemsOnScreen = Math.floor(root.width / itemWidth)
        const visible = Math.min(maxItemsOnScreen, maxWallpapers, root.filteredWallpapers.length)
        if (visible <= 1) return 1
        if (visible % 2 === 0) return visible - 1
        return Math.max(5, visible)
    }

    FolderListModel {
        id: wallpaperModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"]
        showDirs: false
        showFiles: true
        showHidden: false
        showOnlyReadable: true
    }

    readonly property var filteredWallpapers: {
        const paths = []
        for (let i = 0; i < wallpaperModel.count; i++) {
            const fileName = wallpaperModel.get(i, "fileName")
            const filePath = wallpaperModel.get(i, "filePath")
            if (!root.filterText || root.filterText.length === 0) {
                paths.push(filePath.toString())
            } else {
                const lower = root.filterText.toLowerCase()
                if (fileName.toLowerCase().includes(lower)) {
                    paths.push(filePath.toString())
                }
            }
        }
        return paths
    }

    property int currentIndex: 0
    property bool initialized: false
    property string savedPath: ""

    readonly property string currentPath: {
        if (root.currentIndex >= 0 && root.currentIndex < root.filteredWallpapers.length) {
            return root.filteredWallpapers[root.currentIndex]
        }
        return ""
    }

    // When wallpapers load, set currentIndex
    onFilteredWallpapersChanged: {
        if (root.filteredWallpapers.length === 0) return
        if (root.initialized) return

        if (root.savedPath.length > 0) {
            for (let i = 0; i < root.filteredWallpapers.length; i++) {
                if (root.filteredWallpapers[i] === root.savedPath) {
                    root.currentIndex = i
                    root.initialized = true
                    return
                }
            }
        }
        root.currentIndex = 0
        root.initialized = true
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: false

        onLoaded: {
            root.savedPath = text().trim()
            // Try to set currentIndex now if wallpapers are already loaded
            if (root.filteredWallpapers.length > 0 && !root.initialized) {
                if (root.savedPath.length > 0) {
                    for (let i = 0; i < root.filteredWallpapers.length; i++) {
                        if (root.filteredWallpapers[i] === root.savedPath) {
                            root.currentIndex = i
                            root.initialized = true
                            return
                        }
                    }
                }
                root.currentIndex = 0
                root.initialized = true
            }
        }
    }

    function goLeft() {
        if (root.filteredWallpapers.length <= 1) return
        if (root.currentIndex > 0) {
            root.currentIndex--
        } else {
            root.currentIndex = root.filteredWallpapers.length - 1
        }
    }

    function goRight() {
        if (root.filteredWallpapers.length <= 1) return
        if (root.currentIndex < root.filteredWallpapers.length - 1) {
            root.currentIndex++
        } else {
            root.currentIndex = 0
        }
    }

    function applyWallpaper() {
        const path = root.currentPath
        if (path.length === 0) return

        Quickshell.execDetached([
            "awww", "img", path,
            "--transition-type", "random",
            "--transition-fps", "60"
        ])

        Quickshell.execDetached([
            "matugen", "image", path,
            "--prefer", "darkness",
            "--quiet"
        ])

        Quickshell.execDetached(["sh", "-c", `printf '%s' '${path}' > '${root.statePath}'`])

        root.applied(path)
    }

    Row {
        id: carouselRow
        anchors.fill: parent
        spacing: 0

        NavButton {
            id: leftButton
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_left"
            colors: root.colors
            visible: root.filteredWallpapers.length > 1
            onClicked: root.goLeft()
        }

        PathView {
            id: pathView
            width: parent.width - leftButton.width - rightButton.width
            height: parent.height

            clip: true
            model: root.filteredWallpapers.length
            currentIndex: root.currentIndex
            onCurrentIndexChanged: root.currentIndex = currentIndex

            path: Path {
                startY: pathView.height / 2
                PathAttribute { name: "z"; value: 0 }
                PathLine { x: pathView.width / 2; relativeY: 0 }
                PathAttribute { name: "z"; value: 1 }
                PathLine { x: pathView.width; relativeY: 0 }
            }

            pathItemCount: root.numItems
            cacheItemCount: 4
            snapMode: PathView.SnapToItem
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange

            delegate: WallpaperItem {
                required property int index
                modelData: root.filteredWallpapers[index]
                colors: root.colors
            }
        }

        NavButton {
            id: rightButton
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_right"
            colors: root.colors
            visible: root.filteredWallpapers.length > 1
            onClicked: root.goRight()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: noFoundText.implicitWidth + 32
        height: noFoundText.implicitHeight + 24
        radius: 12
        color: colors.m3.surface_container
        visible: root.filteredWallpapers.length === 0

        Text {
            id: noFoundText
            anchors.centerIn: parent
            text: root.filterText.length > 0 ? "No wallpapers match your search" : "No wallpapers found in ~/Pictures/Wallpapers"
            color: colors.m3.on_surface_variant
            font.pixelSize: 14
            font.family: "Rubik"
        }
    }
}
