pragma ComponentBehavior: Bound

// ControlCenterWindow.qml
// Side panel that slides in from the right — styled after the reference repo.
// Replaces the old top-right popup approach.

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io
import "../../qs/services"
import "components"

PanelWindow {
    id: root

    // ── Layer shell setup ────────────────────────────────────────────────────
    WlrLayershell.layer:          WlrLayershell.Top
    WlrLayershell.namespace:      "qs-control-center"
    WlrLayershell.keyboardFocus:  shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone:  -1
    color: "transparent"

    anchors { top: true; right: true; bottom: true }
    margins { top: 40 }

    implicitWidth: 380
    visible: shouldShow || container.x < root.width   // keep alive while animating out

    property bool shouldShow: false

    // Toggle function for panel open/close
    function toggle() {
        shouldShow = !shouldShow
    }

    // Restrict input to the visible panel only
    mask: Region {
        item: container.x < root.width ? container : null
    }


    // ── Color tokens (mirrors Colors.m3.* from the reference repo) ───────────
    readonly property color cSurface:              Colors.m3.surface
    readonly property color cSurfaceContainer:     Colors.m3.surface_container
    readonly property color cSurfaceContainerHigh: Colors.m3.surface_container_high
    readonly property color cSurfaceContainerHighest: Colors.m3.surface_container_highest
    readonly property color cOnSurface:            Colors.m3.on_surface
    readonly property color cOnSurfaceVariant:     Colors.m3.on_surface_variant
    readonly property color cPrimary:              Colors.m3.primary
    readonly property color cSecondary:            Colors.m3.secondary
    readonly property color cTertiary:             Colors.m3.tertiary
    readonly property color cError:                Colors.m3.error
    readonly property color cOnError:              Colors.m3.on_error
    readonly property color cOutline:              Colors.m3.outline

    // ── Live system state (driven by Audio singleton, instant PipeWire events) ─
    readonly property int  sinkVolume:   Audio.sinkVolume
    readonly property bool sinkMuted:    Audio.sinkMuted
    readonly property int  sourceVolume: Audio.sourceVolume
    readonly property bool sourceMuted:  Audio.sourceMuted

    // Volume setters — go through Audio singleton (direct PipeWire control)
    function setVolume(v) {
        Audio.setVolume(v)
    }
    function setMicVolume(v) {
        Audio.setMicVolume(v)
    }
    function setBrightness(v) {
        if (Brightness.getActiveMonitor())
            Brightness.getActiveMonitor().setBrightness(v)
    }

    // ── Process launchers ────────────────────────────────────────────────────
    Process { id: lockProcess;  command: ["loginctl", "lock-session"]; onStarted: root.shouldShow = false }
    Process { id: powerProcess; command: ["systemctl", "poweroff"];      onStarted: root.shouldShow = false }

    // ── Keyboard dismiss ─────────────────────────────────────────────────────
    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.shouldShow = false
    }

    // Top level definitions for local state
    property string activePowerProfile: "balanced"
    property bool powerProfileLoading: false
    
    Process {
        id: cmdSyncProfile
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.activePowerProfile = text.trim()
                root.powerProfileLoading = false
            }
        }
    }

    Process {
        id: cmdSetProfile
        property string targetProfile: "balanced"
        command: ["powerprofilesctl", "set", targetProfile]
        onExited: cmdSyncProfile.running = true
    }

    Timer {
        interval: 5000
        running: root.shouldShow
        repeat: true
        onTriggered: cmdSyncProfile.running = true
    }

    onShouldShowChanged: {
        if (shouldShow) {
            cmdSyncProfile.running = true
        }
    }

    // ── Main sliding container ────────────────────────────────────────────────
    Rectangle {
        id: container
        width:  parent.width
        height: parent.height
        color:  root.cSurface
        radius: 20

        // Square the top-right and full-right edge (flush to screen)
        Rectangle { width: parent.width;  height: parent.radius; color: parent.color; anchors.top:   parent.top   }
        Rectangle { width: parent.radius; height: parent.height; color: parent.color; anchors.right: parent.right }



        // Slide in from right
        x:       root.shouldShow ? 0 : root.width
        opacity: root.shouldShow ? 1 : 0

        Behavior on x       { NumberAnimation { duration: 280; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad  } }

        // Click outside to close (only on the transparent region)
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.shouldShow = false
        }

        // ── Content ─────────────────────────────────────────────
        Item {
            anchors.fill:    parent
            anchors.margins: 16
            clip:            true

            Column {
                id: innerCol
                anchors.fill: parent
                spacing: 20

                // ── Header ────────────────────────────────────────────────
                Item {
                    width:  parent.width
                    height: 56

                    // Time + date
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            id: timeText
                            text: Qt.formatTime(new Date(), "hh:mm")
                            color: root.cOnSurface
                            font.family: "Inter"
                            font.weight: Font.Bold
                            font.pixelSize: 28
                        }
                        Text {
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            color: root.cOnSurfaceVariant
                            font.family: "Inter"
                            font.pixelSize: 13
                        }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
                        }
                    }

                    // Header action buttons
                    Row {
                        anchors.right:          parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        // Screenshot
                        HeaderIconBtn {
                            iconText: "camera_alt"
                            onClicked: {
                                root.toggle()
                                ScreenshotService.toggleMenu()
                            }
                        }
                        // Lock
                        HeaderIconBtn {
                            iconText: "lock"
                            onClicked: lockProcess.running = true
                        }
                        // Power
                        HeaderIconBtn {
                            iconText: "power_settings_new"
                            onClicked: powerProcess.running = true
                        }
                        // Close
                        HeaderIconBtn {
                            iconText: "close"
                            onClicked: root.shouldShow = false
                        }
                    }
                }

                // ── Quick toggles (2-column grid) ─────────────────────────
                GridLayout {
                    width:         parent.width
                    columns:       2
                    columnSpacing: 10
                    rowSpacing:    10

                    // Wi-Fi
                    QuickToggle {
                        Layout.fillWidth: true
                        icon:        Network.wifiEnabled ? "󰖩" : "󰖪"
                        label:       "Wi-Fi"
                        subLabel:    Network.wifiEnabled ? Network.activeSsid : "Disabled"
                        active:      Network.wifiEnabled
                        activeColor: root.cPrimary
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor:   root.cOnSurface
                        showArrow:   true
                        onClicked:   Network.toggleWifi()
                        onArrowClicked: {
                            root.toggle()
                            NetworkMenuService.open("wifi")
                        }
                    }

                    // Bluetooth
                    QuickToggle {
                        Layout.fillWidth: true
                        icon:        Bluetooth.defaultAdapter?.enabled ? "󰂯" : "󰂲"
                        label:       "Bluetooth"
                        subLabel:    !Bluetooth.defaultAdapter?.enabled ? "Disabled" 
                                   : (Bluetooth.devices.find(d => d.connected)?.name ?? "Enabled")
                        active:      Bluetooth.defaultAdapter?.enabled ?? false
                        activeColor: root.cPrimary
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor:   root.cOnSurface
                        showArrow:   true
                        onClicked: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                            }
                        }
                        onArrowClicked: {
                            root.toggle()
                            NetworkMenuService.open("bluetooth")
                        }
                    }

                    // Power Profile
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: root.activePowerProfile === "power-saver" ? "󰾆" : (root.activePowerProfile === "performance" ? "󰓅" : "󰾅")
                        label: "Power Mode"
                        subLabel: root.activePowerProfile === "power-saver" ? "Power Saver" : (root.activePowerProfile === "performance" ? "Performance" : "Balanced")
                        active: root.activePowerProfile !== "balanced"
                        activeColor: root.activePowerProfile === "performance" ? root.cError : root.cTertiary
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor: root.cOnSurface
                        showArrow: false
                        loading: root.powerProfileLoading
                        onClicked: {
                            root.powerProfileLoading = true
                            // Cycle logic: balanced -> performance -> power-saver -> balanced
                            const next = root.activePowerProfile === "balanced" ? "performance" : (root.activePowerProfile === "performance" ? "power-saver" : "balanced")
                            cmdSetProfile.targetProfile = next
                            cmdSetProfile.running = true
                        }
                    }

                    // Do Not Disturb
                    QuickToggle {
                        Layout.fillWidth: true
                        icon:        NotifService.dnd ? "󰔎" : "󰂛"
                        label:       "Do Not Disturb"
                        subLabel:    NotifService.dnd ? "On" : "Off"
                        active:      NotifService.dnd
                        activeColor: root.cError
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor:   root.cOnSurface
                        showArrow:   false
                        onClicked:   NotifService.dnd = !NotifService.dnd
                    }

                    // Caffeine
                    QuickToggle {
                        Layout.fillWidth: true
                        icon:        "󰅶"
                        label:       "Caffeine"
                        subLabel:    IdleService.enabled ? "Awake" : "Idle"
                        active:      IdleService.enabled
                        activeColor: root.cSecondary
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor:   root.cOnSurface
                        showArrow:   false
                        onClicked:   IdleService.toggle()
                    }

                    // Night Light
                    QuickToggle {
                        Layout.fillWidth: true
                        icon:        NightLightService.enabled ? "󰖔" : "󰖕"
                        label:       "Night Light"
                        subLabel:    NightLightService.enabled ? NightLightService.temperature + "K" : "Off"
                        active:      NightLightService.enabled
                        activeColor: root.cSecondary
                        surfaceColor: root.cSurfaceContainerHigh
                        textColor:   root.cOnSurface
                        showArrow:   true
                        onClicked:   NightLightService.toggle()
                        onArrowClicked: {
                            root.toggle()
                            NightLightService.openMenu()
                        }
                    }
                }

                // ── Sliders ─────────────────────────────────────────────
                Column {
                    width:  parent.width
                    spacing: 10

                    // Volume
                    InlineSlider {
                        width:       parent.width
                        iconText:    root.sinkMuted   ? "volume_off"
                                   : root.sinkVolume > 50 ? "volume_up" : "volume_down"
                        value:       root.sinkVolume / 100
                        accentColor: root.cPrimary
                        trackColor:  root.cSurfaceContainerHighest
                        onChanged: (v) => root.setVolume(v)
                    }


                    // Microphone
                    InlineSlider {
                        width:       parent.width
                        iconText:    root.sourceMuted ? "mic_off" : "mic"
                        value:       root.sourceVolume / 100
                        accentColor: root.cPrimary
                        trackColor:  root.cSurfaceContainerHighest
                        onChanged: (v) => root.setMicVolume(v)
                    }



                     // Brightness
                    InlineSlider {
                        width:       parent.width
                        property real currentBright: Brightness.getActiveMonitor() ? Brightness.getActiveMonitor().brightness : 0.5
                        iconText:    currentBright > 0.6 ? "brightness_high"
                                   : currentBright > 0.3 ? "brightness_medium"
                                   : "brightness_low"
                        value:       currentBright
                        accentColor: root.cPrimary
                        trackColor:  root.cSurfaceContainerHighest
                        onChanged: (v) => { if(Brightness.getActiveMonitor()) Brightness.getActiveMonitor().setBrightness(v) }
                    }
                }

                // ── Media card ────────────────────────────────────────────
                // MediaCard is disabled because mpris is not available
                // MediaCard {
                //     width:  parent.width
                //     mpris:  root.mpris
                //     accentColor: root.cPrimary
                //     textColor: root.cOnSurface
                //     textDim: root.cOnSurfaceVariant
                //     visible: root.mpris.active !== null
                // }

                // ── Notification history ──────────────────────────────────
                Column {
                    width:   parent.width
                    spacing: 12

                    // Header row
                    Item {
                        width:  parent.width
                        height: 32

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:        "Notifications"
                            color:       root.cOnSurface
                            font.family: "Inter"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                        }

                        // Clear All
                        Rectangle {
                            width:  80; height: 30; radius: 15
                            anchors.right:          parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: (NotifService.history?.length ?? 0) > 0
                            color:   clrMa.containsMouse ? root.cError : root.cSurfaceContainerHigh

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text:        "Clear All"
                                color:       clrMa.containsMouse ? root.cOnError : root.cOnSurfaceVariant
                                font.family: "Inter"
                                font.weight: Font.Medium
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: clrMa; anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    NotifService.clearHistory()
                            }
                        }
                    }

                    // Notification list
                    Column {
                        width:   parent.width
                        spacing: 10

                        Repeater {
                            model: NotifService.history ?? []

                            delegate: Rectangle {
                                required property var modelData
                                width:  parent.width
                                height: notifRow.implicitHeight + 20
                                radius: 14
                                color:  notifHover.containsMouse
                                        ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.06)
                                        : root.cSurfaceContainerHigh

                                Behavior on color { ColorAnimation { duration: 100 } }

                                MouseArea {
                                    id: notifHover; anchors.fill: parent
                                    hoverEnabled: true; z: -1
                                }

                                RowLayout {
                                    id: notifRow
                                    anchors { fill: parent; margins: 10 }
                                    spacing: 12

                                    // App icon
                                    Rectangle {
                                        Layout.preferredWidth:  40
                                        Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignTop
                                        radius: 12
                                        color: Qt.rgba(root.cPrimary.r, root.cPrimary.g, root.cPrimary.b, 0.15)

                                        Image {
                                            anchors.centerIn: parent
                                            width: 22; height: 22
                                            source: {
                                                const ic = modelData.icon ?? ""
                                                if (!ic) return ""
                                                return ic.startsWith("/") ? ic : "image://icon/" + ic
                                            }
                                            visible: status === Image.Ready
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰂚"
                                            font.family:  "Material Design Icons"
                                            font.pixelSize: 18
                                            color: root.cPrimary
                                            visible: parent.children[0].status !== Image.Ready
                                        }
                                    }

                                    // Text
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: modelData.summary ?? "Notification"
                                            color: root.cOnSurface
                                            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 13
                                            elide: Text.ElideRight; Layout.fillWidth: true
                                        }
                                        Text {
                                            text: modelData.body ?? ""
                                            color: root.cOnSurfaceVariant
                                            font.family: "Inter"; font.pixelSize: 12
                                            elide: Text.ElideRight; wrapMode: Text.WordWrap
                                            maximumLineCount: 2; Layout.fillWidth: true
                                            visible: text !== ""
                                        }
                                        Text {
                                            text: {
                                                const t = modelData.time
                                                return t ? Qt.formatTime(t, "hh:mm") : ""
                                            }
                                            color: Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.4)
                                            font.family: "Inter"; font.pixelSize: 11
                                            visible: text !== ""
                                        }
                                    }

                                    // Close
                                    Rectangle {
                                        Layout.preferredWidth:  28
                                        Layout.preferredHeight: 28
                                        Layout.alignment: Qt.AlignTop
                                        radius: 14
                                        color: xMa.containsMouse
                                               ? Qt.rgba(root.cOnSurface.r, root.cOnSurface.g, root.cOnSurface.b, 0.12)
                                               : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            font.family: "Material Design Icons"; font.pixelSize: 14
                                            color: root.cOnSurfaceVariant
                                        }
                                        MouseArea {
                                            id: xMa; anchors.fill: parent
                                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: NotifService.removeFromHistory(modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        // Empty state
                        Rectangle {
                            width:  parent.width; height: 60; radius: 16
                            color:  root.cSurfaceContainer
                            visible: (NotifService.history?.length ?? 0) === 0

                            Text {
                                anchors.centerIn: parent
                                text:        "No notifications"
                                color:       root.cOnSurfaceVariant
                                font.family: "Inter"; font.pixelSize: 13
                            }
                        }
                    }
                }

                // Bottom padding
                Item { width: 1; height: 8 }
            }
        }
    }

    // ── Inline component: header icon button ─────────────────────────────────
    component HeaderIconBtn: Rectangle {
        id: hib
        property string iconText: ""
        signal clicked()

        width: 36; height: 36; radius: 18
        color: hibMa.containsMouse ? root.cSurfaceContainerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        scale: hibMa.pressed ? 0.90 : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }

        Text {
            anchors.centerIn: parent
            text:             hib.iconText
            font.family:      "Material Icons Round"
            font.pixelSize:   20
            color:            root.cOnSurfaceVariant
        }

        MouseArea {
            id: hibMa; anchors.fill: parent
            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: hib.clicked()
        }
    }

// ── Inline component: Circle-Thumb Slider ───────
    component InlineSlider: Item {
        id: sliderRoot
        property string iconText: "volume_up"
        property real value: 0.5
        property color accentColor: root.cPrimary
        property color trackColor: root.cSurfaceContainerHighest
        signal changed(real newValue)

        implicitWidth: parent.width
        implicitHeight: 36

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: sliderRoot.trackColor
        }

        Rectangle {
            height: parent.height
            width: thumb.x + thumb.width
            radius: height / 2
            color: sliderRoot.accentColor
            opacity: 0.4 
            
            Behavior on width { 
                NumberAnimation { 
                    duration: sliderMouseArea.pressed ? 0 : 150 
                    easing.type: Easing.OutQuad 
                } 
            }
        }

        Rectangle {
            id: thumb
            height: parent.height
            width: 56
            radius: height / 2
            color: sliderRoot.accentColor
            
            x: (isNaN(sliderRoot.value) ? 0 : sliderRoot.value) * (parent.width - width)
            
            Behavior on x { 
                NumberAnimation { 
                    duration: sliderMouseArea.pressed ? 0 : 150 
                    easing.type: Easing.OutQuad 
                } 
            }

            Row {
                anchors.centerIn: parent
                spacing: 2
                
                Text {
                    text: sliderRoot.iconText
                    font.family: "Material Icons Round"
                    font.pixelSize: 16
                    color: Qt.rgba(0, 0, 0, 0.8) 
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: Math.round((isNaN(sliderRoot.value) ? 0 : sliderRoot.value) * 100) + "%"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Qt.rgba(0, 0, 0, 0.8)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            id: sliderMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            
            function updateValue(mouseX) {
                if (width <= 0) return; 
                
                let minX = thumb.width / 2;
                let maxX = width - (thumb.width / 2);
                let clampedX = Math.max(minX, Math.min(maxX, mouseX));
                
                let newValue = (clampedX - minX) / (maxX - minX);
                
                if (isNaN(newValue)) newValue = 0;
                
                sliderRoot.value = newValue;
                sliderRoot.changed(newValue);
            }
            
            onPressed: mouse => updateValue(mouse.x)
            onPositionChanged: mouse => {
                if (pressed) {
                    updateValue(mouse.x)
                }
            }
        }
    }
}
