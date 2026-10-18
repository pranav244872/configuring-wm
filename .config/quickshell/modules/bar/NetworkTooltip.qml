// Network tooltip: the details the bar item deliberately hides (SSID, strength,
// security, IP). A Chaldea frame like the tray menu panel -- waybar's tooltip
// in our language.
//
// Pure presentation: BarNetwork owns the window, the data and the timing. It is
// a plain Item so the preview bench can render it inline (a benchmark can't
// screenshot a separate popup window).
import QtQuick
import qs.modules
import qs.modules.widgets

Item {
    id: root

    property string title: ""
    property string detail: ""
    property string note: ""
    property color titleColor: Theme.colors.fgLayer0
    property color noteColor: Theme.colors.warning

    readonly property int padX: 10
    readonly property int padY: 8

    implicitWidth: Math.max(titleText.implicitWidth, Math.max(detailText.implicitWidth, noteText.implicitWidth)) + 2 * padX
    implicitHeight: col.implicitHeight + 2 * padY

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.layer0
        border.width: Theme.frame.line
        border.color: Theme.colors.outline
    }

    CornerTicks {
        anchors.fill: parent
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            id: titleText
            text: root.title
            color: root.titleColor
            font.pixelSize: Theme.font.size.sm
            font.weight: Font.DemiBold
            font.letterSpacing: Theme.frame.tracking
        }

        StyledText {
            id: detailText
            visible: text.length > 0
            text: root.detail
            color: Theme.colors.subtext
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
        }

        StyledText {
            id: noteText
            visible: text.length > 0
            text: root.note
            color: root.noteColor
            font.pixelSize: Theme.font.size.xs
            font.letterSpacing: Theme.frame.tracking
        }
    }
}
