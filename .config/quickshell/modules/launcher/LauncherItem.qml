// App item: Papirus icon + uppercase name + subtitle. Chaldea rows: square,
// 1px separation, solid primary selection with dark text, click ripple.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules
import qs.modules.widgets
import qs.modules.launcher

Item {
    id: root

    required property var app
    required property bool selected
    signal activated()

    implicitWidth: parent?.width ?? 364
    implicitHeight: 54

    Rectangle {
        id: bg
        anchors.fill: parent
        anchors.margins: 2
        radius: 0
        clip: true

        color: root.selected ? Theme.colors.primary
            : (mouseArea.containsMouse ? Theme.colors.stateHover : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: Theme.animation.valueDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animation.curveOut
            }
        }

        Ripple {
            id: ripple
            anchors.fill: parent
            color: root.selected ? ColorUtils.transparentize(Theme.colors.fgPrimary, 0.7)
                                 : ColorUtils.transparentize(Theme.colors.fgLayer1, 0.75)
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Item {
                id: iconBox
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36

                readonly property string resolvedIcon: {
                    const raw = root.app?.icon ?? "";
                    if (!raw) return "";
                    return Quickshell.iconPath(raw, true);
                }

                IconImage {
                    id: icon
                    anchors.fill: parent
                    asynchronous: true
                    source: iconBox.resolvedIcon
                    visible: iconBox.resolvedIcon.length > 0 && status !== Image.Error
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Theme.colors.stateHover
                    visible: !icon.visible

                    StyledText {
                        anchors.centerIn: parent
                        text: "apps"
                        font.family: Theme.font.icon
                        font.pixelSize: 22
                        color: Theme.colors.subtext
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 48 - 12
                spacing: 1

                StyledText {
                    width: parent.width
                    text: (root.app?.name ?? "").toUpperCase()
                    font.pixelSize: Theme.font.size.md
                    font.letterSpacing: 1
                    color: root.selected ? Theme.colors.fgPrimary : Theme.colors.fgLayer0
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: (root.app?.genericName || root.app?.comment || root.app?.id || "")
                    font.pixelSize: Theme.font.size.xs
                    color: root.selected ? ColorUtils.transparentize(Theme.colors.fgPrimary, 0.35)
                                         : Theme.colors.subtext
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: (event) => ripple.press(mouseArea.mouseX - bg.x, mouseArea.mouseY - bg.y)
        onReleased: ripple.release()
        onCanceled: ripple.release()
        onClicked: root.activated()
    }
}
