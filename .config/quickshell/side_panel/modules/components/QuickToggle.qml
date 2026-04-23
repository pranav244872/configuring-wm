import QtQuick 6.10
import QtQuick.Layouts 6.10

Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string subLabel: ""
    property bool active: false
    property color activeColor: "#a6e3a1"
    property color surfaceColor: Qt.rgba(1, 1, 1, 0.08)
    property color textColor: "#e6e6e6"
    property bool showArrow: false
    property bool loading: false
    
    signal clicked()
    signal arrowClicked()

    radius: 28
    color: active ? activeColor : surfaceColor
    Behavior on color { ColorAnimation { duration: 180 } }
    Layout.fillWidth: true
    Layout.preferredHeight: 52

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 8

        MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    radius: 18
                    color: active ? Qt.rgba(1,1,1,0.25) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.1)
                    Behavior on color { ColorAnimation { duration: 100 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: root.icon
                        font.family: "Material Design Icons"
                        font.pixelSize: 18
                        color: active ? Qt.rgba(0,0,0,0.87) : root.textColor
                        Behavior on color { ColorAnimation { duration: 100 } }
                        visible: !root.loading
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "sync"
                        font.family: "Material Icons Round"
                        font.pixelSize: 18
                        color: active ? Qt.rgba(0,0,0,0.87) : root.textColor
                        visible: root.loading
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 800
                            running: root.loading
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 8
                    spacing: 2
                    
                    Text {
                        text: root.label
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: active ? Qt.rgba(0,0,0,0.87) : root.textColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    Text {
                        text: root.subLabel
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: active ? Qt.rgba(0,0,0,0.6) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: root.subLabel !== ""
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            visible: root.showArrow

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 16
                color: arrowMouse.containsMouse 
                    ? (active ? Qt.rgba(0,0,0,0.1) : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.15)) 
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                anchors.centerIn: parent
                text: "󰅂"
                font.family: "Material Design Icons"
                font.pixelSize: 24
                color: active ? Qt.rgba(0,0,0,0.54) : root.textColor
            }

            MouseArea {
                id: arrowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.arrowClicked()
            }
        }
    }
}