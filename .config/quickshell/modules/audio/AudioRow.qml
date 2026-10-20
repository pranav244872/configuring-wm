// One audio row.
//
// Device mode: glyph · name · percent · DEFAULT/USE tag; the whole row is the
// target that makes it the default.
// Stream mode: app · its device · percent · mute glyph, over a full-width
// slider.
//
// Values read through the live node when there is one (reactive), and fall back
// to plain fields so the bench can render without PipeWire.
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets
import "audio_model.js" as Audio

Item {
    id: root

    required property var row
    property var node: null
    property bool isDevice: true
    property bool current: false
    property bool interactive: true
    property string target: ""

    signal activated()
    signal muteToggled()
    signal volumeMoved(real value)
    signal volumeCommitted(real value)

    readonly property var audio: root.node && root.node.audio ? root.node.audio : null
    readonly property string label: root.node
        ? (root.isDevice ? Audio.deviceLabel(root.node) : Audio.streamLabel(root.node))
        : String(root.row.label || "")
    readonly property string glyph: root.node
        ? (root.isDevice ? Audio.glyphFor(root.node) : Audio.streamGlyph(root.node))
        : String(root.row.glyph || (root.isDevice ? "speaker" : "graphic_eq"))
    readonly property real volume: root.audio ? root.audio.volume
        : Number(root.row.volume !== undefined ? root.row.volume : 0)
    readonly property bool muted: root.audio ? root.audio.muted : !!root.row.muted
    readonly property string percent: Audio.percent(root.volume)

    implicitHeight: root.isDevice ? 32 : 48

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: hover.hovered && (root.isDevice ? !root.current : true)
            ? Theme.colors.stateHover : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.animation.valueDuration
            }
        }
    }

    // ---------------------------------------------------------------- device
    RowLayout {
        visible: root.isDevice
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 10

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.glyph
            font.family: Theme.font.icon
            font.pixelSize: 18
            color: root.current ? Theme.colors.primary : Theme.colors.subtext
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            font.pixelSize: Theme.font.size.md
            elide: Text.ElideRight
            color: root.current ? Theme.colors.primary : Theme.colors.fgLayer0
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            visible: root.muted
            text: Theme.glyphs.volumeMute
            font.family: Theme.font.icon
            font.pixelSize: 14
            color: Theme.colors.subtext
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: root.percent
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
            color: root.muted ? Theme.colors.subtext : Theme.colors.fgLayer0
            opacity: root.muted ? 0.6 : 1
        }

        // Fixed slot so the tag appearing on hover cannot shift the row.
        Item {
            Layout.preferredWidth: 64
            Layout.fillHeight: true

            StyledText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.current ? "DEFAULT" : (hover.hovered ? "USE" : "")
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: root.current ? Theme.colors.primary : Theme.colors.subtext
            }
        }
    }

    // ---------------------------------------------------------------- stream
    Column {
        visible: !root.isDevice
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 4

        RowLayout {
            width: parent.width
            spacing: 10

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.glyph
                font.family: Theme.font.icon
                font.pixelSize: 18
                color: root.muted ? Theme.colors.subtext : Theme.colors.primary
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.label
                font.pixelSize: Theme.font.size.md
                elide: Text.ElideRight
                color: Theme.colors.fgLayer0
                opacity: root.muted ? 0.6 : 1
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 170
                visible: root.target.length > 0
                text: "ON " + root.target.toUpperCase()
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
                elide: Text.ElideRight
                opacity: 0.7
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: root.percent
                font.pixelSize: Theme.font.size.xs
                font.letterSpacing: Theme.frame.tracking
                color: root.muted ? Theme.colors.subtext : Theme.colors.fgLayer0
                opacity: root.muted ? 0.6 : 1
            }

            Item {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                StyledText {
                    anchors.centerIn: parent
                    text: root.muted ? Theme.glyphs.volumeMute : Theme.glyphs.volumeUp
                    font.family: Theme.font.icon
                    font.pixelSize: 16
                    color: muteMa.containsMouse ? Theme.colors.primary
                        : root.muted ? Theme.colors.subtext : Theme.colors.fgLayer0
                }

                MouseArea {
                    id: muteMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }
        }

        Slider {
            width: parent.width
            value: root.volume
            interactive: root.interactive
            opacity: root.muted ? 0.5 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animation.valueDuration
                }
            }

            onSliderValueChanged: (value) => root.volumeMoved(value)
            onSliderDragFinished: root.volumeCommitted(root.volume)
        }
    }

    // Click target for device rows only: declared BEHIND the labels (plain
    // items do not take input) so the stream slider and mute glyph stay live.
    MouseArea {
        anchors.fill: parent
        enabled: root.isDevice
        acceptedButtons: Qt.LeftButton
        onClicked: root.activated()
    }

    // Passive hover: works over the slider and glyph without stealing a press.
    HoverHandler {
        id: hover
        cursorShape: root.isDevice && !root.current ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
