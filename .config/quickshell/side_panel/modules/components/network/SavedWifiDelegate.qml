import QtQuick 6.10
import QtQuick.Layouts 6.10
import Quickshell
import "../../../../qs/services"

Rectangle {
    id: rootSaved
    height: 42
    radius: 10
    color: rowMa.containsMouse
           ? Qt.rgba(Colors.m3.on_surface.r, Colors.m3.on_surface.g, Colors.m3.on_surface.b, 0.06)
           : Colors.m3.surface_container_highest
    Behavior on color { ColorAnimation { duration: 120 } }

    property string networkName: ""
    signal requestForget(string targetSsid)

    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 10

        Text {
            text: "󰤨"
            font.family: "Material Design Icons"
            font.pixelSize: 16
            color: Colors.m3.on_surface_variant
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: networkName
            elide: Text.ElideRight
            font.family: "Inter"
            font.pixelSize: 13
            color: Colors.m3.on_surface
        }
        
        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 26
            radius: 13
            color: forgetMa.containsMouse ? Colors.m3.error : Colors.m3.error_container
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "Forget"
                font.family: "Inter"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: forgetMa.containsMouse ? Colors.m3.on_error : Colors.m3.on_error_container
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            MouseArea {
                id: forgetMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: requestForget(networkName)
            }
        }
    }
}
