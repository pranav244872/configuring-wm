import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import "../../../qs/services" as Services

Item {
    id: root
    property var mpris: Services.MPRIS
    property string artUrl: ""
    property string trackTitle: mpris.trackTitle || ""
    property string trackArtist: mpris.trackArtist || ""
    property bool isPlaying: mpris.playbackStatus === "Playing"
    property var activePlayer: mpris.activePlayer
    property bool hasPlayer: mpris.hasPlayer
    property color accentColor: mpris.accentColor || "#2196f3"
    property color textColor: mpris.textColor || "#fff"
    property color textDim: mpris.textDim || "#bbb"

    function updateArtUrl() {
        if (mpris && mpris.artUrl) {
            artUrl = mpris.artUrl
        } else {
            artUrl = ""
        }
    }

    clip: true
    visible: hasPlayer

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    // Blurred album art background
    Image {
        id: bgImage
        anchors.fill: parent
        anchors.margins: -20
        source: root.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: bgImage
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.4
        brightness: -0.35
        opacity: bgImage.status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        visible: bgImage.status === Image.Ready
    }

    Timer {
        id: artworkPoller
        interval: 200
        repeat: true
        running: root.hasPlayer && root.artUrl === ""
        property int attempts: 0
        onTriggered: {
            root.updateArtUrl()
            attempts++
            if (attempts > 25 || root.artUrl !== "") {
                running = false
                attempts = 0
            }
        }
    }

    Timer {
        id: initTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            root.updateArtUrl()
            if (root.hasPlayer && root.artUrl === "") {
                artworkPoller.running = true
            }
        }
    }

    Component.onCompleted: {
        updateArtUrl()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 72
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.1)
            clip: true

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.4)
                shadowBlur: 0.3
                shadowVerticalOffset: 2
            }

            Image {
                id: albumArt
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "Material Design Icons"
                font.pixelSize: 32
                color: Qt.rgba(1, 1, 1, 0.3)
                visible: albumArt.status !== Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            Item { Layout.fillHeight: true }
            Text {
                Layout.fillWidth: true
                text: root.trackTitle || "No Media"
                font.family: "Inter"
                font.pixelSize: 15
                font.weight: Font.Bold
                color: root.textColor
                elide: Text.ElideRight
                maximumLineCount: 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.2
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.trackArtist
                font.family: "Inter"
                font.pixelSize: 13
                color: root.textDim
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.2
                }
            }
            Item { Layout.fillHeight: true }
        }

        RowLayout {
            spacing: 2
            ControlButton {
                icon: "󰒮"
                onClicked: {
                    if (root.activePlayer) root.activePlayer.previous()
                }
            }
            Rectangle {
                id: playBtn
                width: 48
                height: 48
                radius: 24
                color: root.accentColor
                scale: playMouse.pressed ? 0.92 : (playMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutQuad
                    }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accentColor
                    shadowBlur: 0.4
                    shadowOpacity: 0.5
                }
                Text {
                    anchors.centerIn: parent
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    font.family: "Material Design Icons"
                    font.pixelSize: 24
                    color: Qt.rgba(0, 0, 0, 0.9)
                }
                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (root.activePlayer) root.activePlayer.togglePlaying()
                    }
                }
            }
            ControlButton {
                icon: "󰒭"
                onClicked: {
                    if (root.activePlayer) root.activePlayer.next()
                }
            }
        }
    }

    component ControlButton: Rectangle {
        property string icon
        signal clicked()
        width: 40
        height: 40
        radius: 20
        color: btnMouse.containsMouse 
            ? Qt.rgba(1, 1, 1, 0.15) 
            : Qt.rgba(1, 1, 1, 0.05)
        scale: btnMouse.pressed ? 0.9 : 1.0
        Behavior on color {
            ColorAnimation {
                duration: 100
                easing.type: Easing.InOutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.InOutQuad
            }
        }
        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: "Material Design Icons"
            font.pixelSize: 22
            color: root.textColor
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }
}
