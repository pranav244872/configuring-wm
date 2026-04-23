// WallpaperItem.qml — Individual wallpaper thumbnail in the carousel
//
// Caelestia-style wallpaper card:
//   - 220px wide, 16:9 aspect ratio (= 124px height)
//   - Sharp corners (matching glow rectangle)
//   - m3surfaceContainer background
//   - Filename label below, centered, 12px Rubik
//   - Selected item: scale 1.0, full opacity, m3primary glow behind
//   - Side items: scale 0.8, 0.5 opacity (semi-transparent)
//
// Expected modelData: string — full file path to the wallpaper image

import QtQuick

Item {
    id: root

    required property string modelData
    required property var colors

    // PathView provides these attached properties
    property bool isCurrentItem: PathView.isCurrentItem || false
    property bool onPath: PathView.onPath || false

    // Thumbnail sizing — smaller to fit 5+ in carousel
    readonly property int imageWidth: 220
    readonly property int imageHeight: Math.round(imageWidth / 16 * 9) // 124
    readonly property int paddingX: 30  // breathing room on sides
    readonly property int topPadding: 8
    readonly property int labelTopMargin: 4
    readonly property int bottomPadding: 16

    implicitWidth: imageWidth + paddingX
    implicitHeight: imageHeight + label.implicitHeight + labelTopMargin + topPadding + bottomPadding

    // Scale and opacity based on PathView state
    // Selected: full scale, full opacity
    // Side items: smaller scale, semi-transparent
    // Off-path: invisible
    scale: isCurrentItem ? 1.0 : (onPath ? 0.8 : 0)
    opacity: isCurrentItem ? 1.0 : (onPath ? 0.5 : 0)
    z: isCurrentItem ? 1 : 0

    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Glow behind the selected item — sharp rectangle matching the thumbnail
    Rectangle {
        anchors.fill: thumbContainer
        anchors.margins: -3
        color: colors.m3.primary
        opacity: root.isCurrentItem ? 0.3 : 0
        visible: root.isCurrentItem

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
    }

    // Thumbnail container — sharp corners
    Rectangle {
        id: thumbContainer
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: topPadding
        }

        width: root.imageWidth
        height: root.imageHeight

        // Background color (shown while image loads or as fallback)
        color: colors.m3.surface_container

        // Fallback icon when image hasn't loaded yet (Material Icons)
        Text {
            anchors.centerIn: parent
            text: "image"
            color: colors.m3.outline_variant
            font.pixelSize: 40
            font.family: "Material Icons Round"
            visible: wallpaperImage.status !== Image.Ready
        }

        // The actual wallpaper image
        Image {
            id: wallpaperImage
            anchors.fill: parent

            source: root.modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }
    }

    // Filename label below the thumbnail (extension stripped)
    Text {
        id: label
        anchors {
            top: thumbContainer.bottom
            topMargin: root.labelTopMargin
            horizontalCenter: parent.horizontalCenter
        }

        width: root.imageWidth - 20
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight

        // Strip file extension from filename
        text: {
            if (!root.modelData) return ""
            var parts = root.modelData.split("/")
            var name = parts[parts.length - 1]
            var lastDot = name.lastIndexOf(".")
            return lastDot > 0 ? name.substring(0, lastDot) : name
        }

        color: root.isCurrentItem ? colors.m3.on_surface : colors.m3.on_surface_variant
        font.pixelSize: 12
        font.family: "Rubik"

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
}
