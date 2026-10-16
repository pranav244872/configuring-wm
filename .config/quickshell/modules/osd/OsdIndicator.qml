// The OSD pill's contents: icon + name + value + bar.
// Pure visual - all state comes in as properties.
//
// The pill width is a fixed token, never derived from its content (that is what
// end-4's OsdValueIndicator does), and the icon sits in a fixed-size box, so a
// different icon or a 3-digit vs 1-digit value can't make the pill resize.

import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.modules.widgets

Item {
    id: pill

    required property string label
    required property string glyph
    required property real value        // 0..1
    property bool muted: false
    property bool locked: false         // true = display only, no dragging

    // Forwarded from the slider so the host owns writing values.
    signal sliderValueChanged(real value)
    signal sliderDragFinished()
    readonly property bool pointerOnSlider: slider.hovered || slider.dragging

    implicitWidth: Theme.sizes.osdWidth
    implicitHeight: Theme.sizes.osdHeight - 8

    Rectangle {                                   // pill surface
        id: surface
        anchors {
            fill: parent
            margins: 4
        }
        radius: Theme.rounding.full
        color: Theme.colors.layer0
        border.width: 2
        border.color: Theme.colors.primary

        RowLayout {
            id: row
            anchors {
                fill: parent
                leftMargin: Theme.sizes.padding
                rightMargin: Theme.sizes.paddingEnd
            }
            spacing: Theme.sizes.md

            // Fixed box: the icon can never influence the layout.
            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Theme.sizes.iconSize
                Layout.preferredHeight: Theme.sizes.iconSize

                Glyph {
                    anchors.centerIn: parent
                    text: pill.glyph
                    color: pill.muted ? Theme.colors.subtext : Theme.colors.primary
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: Theme.sizes.xs + 1

                Item {
                    Layout.fillWidth: true
                    implicitHeight: nameText.implicitHeight

                    StyledText {
                        id: nameText
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.colors.subtext
                        font.pixelSize: Theme.font.size.xs
                        font.weight: Font.Medium
                        text: pill.label
                    }

                    StyledText {
                        id: valueText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.colors.fgLayer0
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.size.sm
                        font.weight: Font.DemiBold
                        text: Math.round(pill.value * 100) + "%"
                    }
                }

                Slider {
                    id: slider
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: pill.value
                    fillColor: pill.muted ? Theme.colors.subtext : Theme.colors.primary
                    interactive: !pill.locked

                    onSliderValueChanged: newValue => pill.sliderValueChanged(newValue)
                    onSliderDragFinished: pill.sliderDragFinished()
                }
            }
        }
    }
}