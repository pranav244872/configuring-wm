// The filmstrip. A horizontal ListView with StrictlyEnforceRange pins the
// current cell to the centre, so the view only ever follows the index -- the
// pointer never drags the strip. (DMS's WallpaperCarousel does the same and
// documents why: flickable snapping drifts against the deck spacing and
// desyncs from the host.) Every move uses our 70ms moveDuration, so a step
// reads exactly like the workspace pill and the dashboard tabs.
//
// Browsing does not apply anything: wheel and left/right only step the index.
// A click applies that slide (the picker shows the images, so the choice is
// made on sight).
import QtQuick
import Quickshell
import qs.modules
import qs.modules.widgets
import qs.modules.wallpaper

Item {
    id: root

    // Centre slot -- the slide the highlight border sits on.
    property int currentIndex: 0

    signal indexRequested(int index)
    signal activated(string path)

    readonly property real pitch: Theme.wallpaper.slideWidth + Theme.wallpaper.slideGap
    readonly property int count: WallpaperService.folder.count
    // Half the growth of the centred slide: the strip reserves this above and
    // below the frames, so the enlarged one is never clipped.
    readonly property int scalePad: Math.ceil(Theme.wallpaper.slideHeight
                                              * (Theme.wallpaper.slideFocusScale - 1) / 2)

    implicitWidth: Theme.wallpaper.slideWidth
    // scale pad + frame + scale pad + label gap + label row
    implicitHeight: root.scalePad + Theme.wallpaper.slideHeight + root.scalePad
                    + Theme.wallpaper.labelGap + Theme.wallpaper.labelHeight

    // The view only ever follows the index; ListView also resets its own
    // currentIndex when its model changes or reloads.
    function syncList() {
        if (list.currentIndex !== root.currentIndex)
            list.currentIndex = root.currentIndex;
    }

    ListView {
        id: list

        anchors.fill: parent
        orientation: ListView.Horizontal
        model: WallpaperService.folder
        spacing: Theme.wallpaper.slideGap
        clip: true

        // The index drives the view, never the pointer.
        interactive: false
        keyNavigationEnabled: false
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (list.width - Theme.wallpaper.slideWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin + Theme.wallpaper.slideWidth
        highlightMoveDuration: Theme.animation.moveDuration
        cacheBuffer: root.pitch * 2

        // ListView resets currentIndex when its model changes or reloads.
        onCountChanged: Qt.callLater(root.syncList)
        Component.onCompleted: currentIndex = root.currentIndex

        delegate: Item {
            id: slide

            required property int index
            required property string filePath
            required property string fileName

            width: Theme.wallpaper.slideWidth
            height: root.implicitHeight

            readonly property bool centred: slide.index === root.currentIndex
            readonly property bool applied: slide.filePath === WallpaperService.current

            // 0 at the centre, 1 a pitch away: the sides dim by this much.
            // `x` is in content coordinates, so the scroll offset comes off it
            // first -- without `contentX` every slide clamps to "one pitch
            // away" and the whole strip renders at the dimmed alpha, centred
            // slide included (measured 2026-10-19: the accent border came out
            // #517e82, exactly primary at 50%, while a corner tick rendered the
            // true #80d4dc).
            readonly property real distance: Math.min(1, Math.abs(slide.x - list.contentX
                                                                   + slide.width / 2
                                                                   - list.width / 2)
                                                        / Math.max(1, root.pitch))

            opacity: 1 - (1 - Theme.wallpaper.neighbourAlpha) * slide.distance

            Rectangle {
                id: frame

                anchors.top: parent.top
                anchors.topMargin: root.scalePad
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.wallpaper.slideWidth
                height: Theme.wallpaper.slideHeight
                color: Theme.colors.layer1
                // A focused window's treatment for the centred slide: 2px accent
                // border (our border_size), hairline outline everywhere else.
                border.width: slide.centred ? Theme.wallpaper.focusBorder : Theme.frame.line
                border.color: slide.centred ? Theme.colors.primary : Theme.colors.outline

                // The centred slide grows a little. `scale` is layout-free, so
                // every label stays on the same baseline.
                scale: slide.centred ? Theme.wallpaper.slideFocusScale : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animation.moveDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.animation.curveMove
                    }
                }

                // A Rectangle's border paints inside its bounds, so the image is
                // inset by the border width to leave it visible.
                Image {
                    anchors.fill: parent
                    anchors.margins: frame.border.width
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: "file://" + slide.filePath
                    // Decode at the size we draw: thumbnails without a
                    // thumbnailer (no ImageMagick on this machine).
                    sourceSize: Qt.size(width * (QsWindow.window?.devicePixelRatio ?? 1),
                                        height * (QsWindow.window?.devicePixelRatio ?? 1))
                    // Photos differ in size and brightness, and browsing fast
                    // would pop them in one by one: fade each one up instead.
                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animation.valueDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.animation.curveOut
                        }
                    }
                }

                // The applied wallpaper: solid accent fill with dark text, our
                // selected-row treatment (launcher rows, active tab block).
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: frame.border.width + 2
                    width: 16
                    height: 16
                    color: Theme.colors.primary
                    visible: slide.applied

                    Glyph {
                        anchors.centerIn: parent
                        text: Theme.glyphs.wallpaperApplied
                        color: Theme.colors.layer0
                        font.pixelSize: 12
                    }
                }
            }

            StyledText {
                anchors.top: frame.bottom
                // Clears the grown centre as well as the base gap, so the label
                // never collides with the enlarged frame.
                anchors.topMargin: root.scalePad + Theme.wallpaper.labelGap
                width: parent.width
                height: Theme.wallpaper.labelHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                font.capitalization: Font.AllUppercase
                color: slide.applied ? Theme.colors.primary : Theme.colors.subtext
                text: slide.fileName.replace(/\.[^.]+$/, "")
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.indexRequested(slide.index);
                    root.activated(slide.filePath);
                }
            }
        }
    }

    // Wheel catcher, declared last on purpose: a later sibling gets the event
    // first, and acceptedButtons = NoButton means it can never take a click, so
    // the slides below keep every press. (The dashboard tab row instead relies
    // on an unhandled wheel propagating down to a catcher declared first -- a
    // ListView is a Flickable, so owning the wheel from above is deterministic.)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            if (delta === 0 || root.count === 0)
                return;
            // A carousel wraps: past the last slide comes the first one again,
            // and stepping back from the first lands on the last.
            root.indexRequested(delta < 0 ? (root.currentIndex + 1) % root.count
                                          : (root.currentIndex - 1 + root.count) % root.count);
            wheel.accepted = true;
        }
    }

    onCurrentIndexChanged: root.syncList()
}
