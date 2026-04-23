pragma ComponentBehavior: Bound

// LockSurface.qml — Full lockscreen surface for each monitor
//
// Displays:
//   - Blurred screen capture background (via ScreencopyView)
//   - Centered card with clock, date, avatar, password input
//   - Power action buttons (logout, suspend, restart, shutdown)

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../../qs/services"

WlSessionLockSurface {
    id: root

    required property LockContext context
    required property WlSessionLock lock
    property string wallpaperPath: ""

    readonly property alias unlocking: unlockAnim.running

    Connections {
        target: root.lock
        function onUnlock() {
            unlockAnim.start()
        }
    }

    // Use transparent - background handled by content
    color: "transparent"

    // State properties
    property string clockHours: ""
    property string clockMinutes: ""
    property string clockDate: ""
    property bool capsLockOn: false
    property bool showPassword: false

    // Unlock animation: fade out everything, then unlock after delay
    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation {
                target: content
                property: "scale"
                to: 0
                duration: 200
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: 200
            }
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: 300
            }
            NumberAnimation {
                target: wallpaperImage
                property: "opacity"
                to: 0
                duration: 300
            }
            NumberAnimation {
                target: darkOverlay
                property: "opacity"
                to: 0
                duration: 300
            }
            SequentialAnimation {
                PauseAnimation { duration: 200 }
                NumberAnimation {
                    target: lockContent
                    property: "opacity"
                    to: 0
                    duration: 200
                }
            }
        }
        PropertyAction {
            target: unlockDelay
            property: "running"
            value: true
        }
    }

    // Timer to actually unlock after animations finish
    Timer {
        id: unlockDelay
        interval: 300
        running: false
        repeat: false
        onTriggered: root.lock.locked = false
    }

    // Init animation: fade in wallpaper, scale + rotate card, show content
    ParallelAnimation {
        id: initAnim

        running: true

        SequentialAnimation {
            PauseAnimation { duration: 100 }
            ParallelAnimation {
                NumberAnimation {
                    target: lockContent
                    property: "scale"
                    to: 1
                    duration: 500
                    easing.type: Easing.OutQuint
                }
                NumberAnimation {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
            ParallelAnimation {
                NumberAnimation {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: lockIcon
                    property: "opacity"
                    to: 0
                    duration: 300
                }
                NumberAnimation {
                    target: content
                    property: "opacity"
                    to: 1
                    duration: 300
                }
                NumberAnimation {
                    target: content
                    property: "scale"
                    to: 1
                    duration: 300
                    easing.type: Easing.OutQuint
                }
            }
        }
    }

    // Fetch current wallpaper path from awww (runs fresh each time lock surface is created)
    Process {
        id: wallpaperFetch
        command: ["sh", "-c", "awww query"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var lines = text.trim().split('\n')
                    for (var i = 0; i < lines.length; i++) {
                        var match = lines[i].match(/image:\s*(.+)$/)
                        if (match) {
                            root.wallpaperPath = match[1].trim()
                            console.log("[LockSurface] Wallpaper from awww:", root.wallpaperPath)
                            return
                        }
                    }
                } catch(e) {
                    console.error("[LockSurface] awww parse error:", e)
                }
                // Fallback to cache file
                cacheWallpaperFetch.running = true
            }
        }
    }

    // Fallback: read cached wallpaper path
    Process {
        id: cacheWallpaperFetch
        command: ["cat", Quickshell.env("HOME") + "/.cache/qs-wallpaper-path"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p) {
                    root.wallpaperPath = p
                    console.log("[LockSurface] Wallpaper from cache:", p)
                }
            }
        }
    }

    // Blurred wallpaper background
    Image {
        id: wallpaperImage

        anchors.fill: parent
        source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        cache: false
        opacity: 0
        visible: source !== ""

        onStatusChanged: {
            if (status === Image.Ready) {
                fadeInWallpaper.start()
            }
        }

        NumberAnimation {
            id: fadeInWallpaper
            target: wallpaperImage
            property: "opacity"
            to: 1
            duration: 300
            easing.type: Easing.OutQuad
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.8
            blurMax: 32
            blurMultiplier: 1
        }
    }

    // Dark overlay for depth
    Rectangle {
        id: darkOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: 0.4
    }

    // Centered card — full size, scale animated
    Item {
        id: lockContent

        anchors.centerIn: parent
        width: Math.min(root.width * 0.85, 500)
        height: Math.min(root.height * 0.75, 550)

        rotation: 180
        scale: 0

        // Card background
        Rectangle {
            id: lockBg

            anchors.fill: parent
            color: Colors.m3.surface_container
            radius: 28
        }

        // Lock icon shown during unlock animation
        Text {
            id: lockIcon

            anchors.centerIn: parent
            text: "\ue897"
            font.family: "Material Icons Round"
            font.pointSize: 64
            font.bold: true
            color: Colors.m3.primary
            rotation: 180
            opacity: 0
        }

        // Main content (clock, avatar, password)
        ColumnLayout {
            id: content

            anchors.centerIn: parent
            width: parent.width - 64
            height: parent.height - 64

            opacity: 0
            scale: 0
            spacing: 20

            // Clock: HH : MM
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                Text {
                    text: root.clockHours
                    color: Colors.m3.secondary
                    font.pointSize: 64
                    font.family: "Inter"
                    font.bold: true
                }

                Text {
                    text: ":"
                    color: Colors.m3.primary
                    font.pointSize: 64
                    font.family: "Inter"
                    font.bold: true
                }

                Text {
                    text: root.clockMinutes
                    color: Colors.m3.secondary
                    font.pointSize: 64
                    font.family: "Inter"
                    font.bold: true
                }
            }

            // Full date
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -12

                text: root.clockDate
                color: Colors.m3.tertiary
                font.pointSize: 16
                font.family: "Inter"
            }

            // Avatar circle
            Rectangle {
                Layout.topMargin: 16
                Layout.alignment: Qt.AlignHCenter

                implicitWidth: 100
                implicitHeight: 100

                color: Colors.m3.surface_container_high
                radius: 50

                Text {
                    anchors.centerIn: parent
                    text: "\ue7fd"
                    font.family: "Material Icons Round"
                    color: Colors.m3.on_surface_variant
                    font.pointSize: 40
                    visible: pfp.status !== Image.Ready
                }

                Image {
                    id: pfp
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    visible: status === Image.Ready
                }
            }

            // Password input — single pill with merged eye button
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8

                implicitWidth: 300
                implicitHeight: 48

                color: Colors.m3.surface_container_high
                radius: 24
                border.color: Colors.m3.outline_variant
                border.width: 1

                // Password TextField
                TextField {
                    id: passwordBox

                    anchors {
                        left: parent.left
                        right: eyeButton.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 16
                        rightMargin: 4
                    }

                    focus: true
                    enabled: !root.context.unlockInProgress
                    echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData

                    placeholderText: "Enter password"
                    placeholderTextColor: Colors.m3.outline_variant

                    color: Colors.m3.on_surface
                    font.pointSize: 14
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.letterSpacing: 4

                    verticalAlignment: TextInput.AlignVCenter
                    background: Item {}

                    onTextChanged: root.context.currentText = text
                    onAccepted: root.context.tryUnlock()

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText
                        }
                    }
                }

                // Eye button integrated into the pill
                Rectangle {
                    id: eyeButton

                    anchors {
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        rightMargin: 4
                    }

                    width: height
                    color: "transparent"
                    radius: 20

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.showPassword = !root.showPassword
                        cursorShape: Qt.PointingHandCursor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.showPassword ? "\ue8f5" : "\ue417"
                        font.family: "Material Icons Round"
                        font.pointSize: 16
                        color: root.showPassword ? Colors.m3.primary : Colors.m3.on_surface_variant
                    }
                }
            }

            // Caps lock indicator — always reserves space
            Text {
                text: root.capsLockOn ? "Caps Lock is ON" : ""
                color: Colors.m3.on_surface_variant
                font.pointSize: 11
                font.family: "JetBrainsMono Nerd Font Mono"
                Layout.alignment: Qt.AlignHCenter
                Layout.minimumHeight: 16

                opacity: root.capsLockOn ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }

            // Failure message
            Text {
                visible: root.context.showFailure
                text: "Incorrect password. Please try again."
                color: Colors.m3.error
                font.pointSize: 12
                font.family: "JetBrainsMono Nerd Font Mono"
                Layout.alignment: Qt.AlignHCenter
            }

            // Power actions row
            RowLayout {
                Layout.topMargin: 16
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                PowerButton {
                    icon: "exit_to_app"
                    label: "Log Out"
                    buttonColor: Colors.m3.on_surface_variant
                    onClicked: Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
                }

                PowerButton {
                    icon: "bedtime"
                    label: "Suspend"
                    buttonColor: Colors.m3.primary
                    onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                }

                PowerButton {
                    icon: "restart_alt"
                    label: "Restart"
                    buttonColor: Colors.m3.tertiary
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }

                PowerButton {
                    icon: "power_settings_new"
                    label: "Shutdown"
                    buttonColor: Colors.m3.error
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }
    }

    // Timer to update clock every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            root.clockHours = Qt.formatTime(now, "hh")
            root.clockMinutes = Qt.formatTime(now, "mm")
            root.clockDate = Qt.formatDate(now, "dddd, d MMMM yyyy")
        }
    }

    // Poll caps lock state via hyprctl every 200ms
    Process {
        id: capsLockProc

        command: ["sh", "-c", "hyprctl -j devices"]
        running: false

        stdout: StdioCollector {
            id: capsLockStdout
            onStreamFinished: {
                try {
                    var devices = JSON.parse(text)
                    var keyboards = devices.keyboards || []
                    for (var i = 0; i < keyboards.length; i++) {
                        if (keyboards[i].main === true) {
                            root.capsLockOn = keyboards[i].capsLock === true
                            return
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: capsLockPollInit
        interval: 300
        running: true
        repeat: false
        onTriggered: capsLockProc.running = true
    }

    Timer {
        id: capsLockPollInterval
        interval: 200
        repeat: true
        running: true
        onTriggered: capsLockProc.running = true
    }

    Component.onCompleted: {
        var now = new Date()
        root.clockHours = Qt.formatTime(now, "hh")
        root.clockMinutes = Qt.formatTime(now, "mm")
        root.clockDate = Qt.formatDate(now, "dddd, d MMMM yyyy")
        // Fetch fresh wallpaper path each time lock surface is created
        wallpaperFetch.running = true
    }
}
