// The sheet's contents: the Chaldea header row, a rule, and the filmstrip. There
// is deliberately no backdrop image behind the strip -- the slides are the
// previews, and a dimmed copy of the centred one made the sheet read as noisy
// (2026-10-19). It owns the centre slot (the host only asks it
// to step or apply), so the position survives closing and reopening the sheet
// and only resets on a shell restart -- same reasoning as the dashboard's tab.
import QtQuick
import qs.modules
import qs.modules.widgets
import qs.modules.wallpaper

Item {
    id: content

    property int currentIndex: 0

    readonly property int count: WallpaperService.folder.count
    readonly property string centredPath: WallpaperService.pathAt(content.currentIndex)

    function pad(value) {
        return String(value).padStart(2, "0");
    }

    // On open: centre on what is actually on screen, so the picker starts where
    // the desktop is (and recovers if the library changed under us).
    function activate() {
        const applied = WallpaperService.indexOf(WallpaperService.current);
        content.currentIndex = applied >= 0 ? applied : 0;
    }

    function step(delta) {
        if (content.count === 0)
            return;
        // A carousel wraps: after the last slide comes the first one again.
        content.currentIndex = (content.currentIndex + delta + content.count) % content.count;
    }

    function applyCurrent() {
        WallpaperService.apply(content.centredPath);
    }

    // Keep the centre slot valid if the library shrinks while the sheet is up.
    onCountChanged: if (content.currentIndex > content.count - 1)
                        content.currentIndex = Math.max(0, content.count - 1)

    Column {
        anchors.fill: parent

        // Header: tracked uppercase label left, position counter right -- the
        // dashboard's section header, scoped to one tab.
        Item {
            width: parent.width
            height: Theme.wallpaper.labelHeight

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "WALLPAPERS"
                color: Theme.colors.subtext
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.titleTrack
            }

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: content.pad(content.count === 0 ? 0 : content.currentIndex + 1)
                      + " / " + content.pad(content.count)
                color: Theme.colors.subtext
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.titleTrack
            }
        }

        Item {
            width: parent.width
            height: 10
        }

        Rectangle {
            width: parent.width
            height: Theme.frame.line
            color: Theme.colors.outline
        }

        Item {
            width: parent.width
            height: 12
        }

        WallpaperCarousel {
            id: strip

            width: parent.width
            height: implicitHeight
            visible: content.count > 0
            currentIndex: content.currentIndex

            onIndexRequested: (index) => content.currentIndex = index
            onActivated: (path) => WallpaperService.apply(path)
        }

        // Empty library: say so in the frame's own voice instead of showing a
        // blank sheet.
        StyledText {
            width: parent.width
            height: strip.implicitHeight
            visible: content.count === 0
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "NO WALLPAPERS IN ~/PICTURES/WALLPAPERS"
            color: Theme.colors.subtext
            font.pixelSize: Theme.frame.labelSize
            font.letterSpacing: Theme.frame.tracking
        }
    }
}
