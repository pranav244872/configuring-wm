// Audio tab bench: the dashboard sheet on the AUDIO tab, twice -- populated
// (headset default, mic, two playing apps) and muted/empty. Mock rows only:
// PipeWire is never touched. Saves /tmp/opencode/preview_audio.png.
import QtQuick
import Quickshell
import qs.modules
import qs.modules.dashboard

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#39434a"
        implicitWidth: 1520
        implicitHeight: 1080

        readonly property var sinkRows: [
            {
                id: 70,
                name: "alsa_output.usb-Plantronics",
                label: "Blackwire C3220 Headset",
                glyph: "headphones",
                volume: 0.63,
                muted: false,
                current: true
            },
            {
                id: 54,
                name: "alsa_output.pci-0000_00_1f.3.analog-stereo",
                label: "Built-in Audio",
                glyph: "speaker",
                volume: 0.35,
                muted: false,
                current: false
            }
        ]

        readonly property var sourceRows: [
            {
                id: 76,
                name: "alsa_input.usb-Plantronics",
                label: "Blackwire C3220 Headset",
                glyph: "mic",
                volume: 1.0,
                muted: false,
                current: true
            },
            {
                id: 55,
                name: "alsa_input.pci-0000_00_1f.3.analog-stereo",
                label: "Built-in Audio",
                glyph: "mic",
                volume: 0.8,
                muted: false,
                current: false
            }
        ]

        readonly property var streamRows: [
            {
                id: 74,
                name: "Firefox",
                label: "Firefox",
                glyph: "graphic_eq",
                volume: 0.82,
                muted: false,
                target: "Blackwire C3220 Headset"
            },
            {
                id: 68,
                name: "Telegram",
                label: "Telegram",
                glyph: "graphic_eq",
                volume: 0.4,
                muted: false,
                target: "Blackwire C3220 Headset"
            }
        ]

        readonly property var mutedRows: [
            {
                id: 70,
                name: "alsa_output.usb-Plantronics",
                label: "Blackwire C3220 Headset",
                glyph: "headphones",
                volume: 0.63,
                muted: true,
                current: true
            },
            {
                id: 54,
                name: "alsa_output.pci-0000_00_1f.3.analog-stereo",
                label: "Built-in Audio",
                glyph: "speaker",
                volume: 0.35,
                muted: false,
                current: false
            }
        ]

        component Sheet: Item {
            id: sheet

            property alias content: dashboardContent
            property real sheetHeight: Math.round(win.height * Theme.sizes.dashboardAudioHeightRatio)

            width: Theme.sizes.dashboardWidth
            height: sheetHeight

            DashboardSurface {
                anchors.fill: parent
            }

            DashboardContent {
                id: dashboardContent
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                currentTab: dashboardContent.audioTabIndex
            }
        }

        Row {
            id: scene
            anchors.centerIn: parent
            spacing: 24

            Sheet {
                id: liveSheet
            }

            Sheet {
                id: mutedSheet
            }
        }

        Component.onCompleted: {
            const live = liveSheet.content.audio;
            live.mock = true;
            live.mockSinkRows = win.sinkRows;
            live.mockSourceRows = win.sourceRows;
            live.mockStreamRows = win.streamRows;
            live.mockSinkVolume = 0.63;
            live.mockSourceVolume = 1.0;
            live.mockPeak = 0.42;

            const muted = mutedSheet.content.audio;
            muted.mock = true;
            muted.mockSinkRows = win.mutedRows;
            muted.mockSourceRows = [];
            muted.mockStreamRows = [];
            muted.mockSinkVolume = 0.63;
            muted.mockSinkMuted = true;
            muted.mockSourceMuted = true;

            liveSheet.content.audio.activate();
            mutedSheet.content.audio.activate();
            console.log("BENCH mock=" + live.mock + " peak=" + live.peakValue
                        + " src=" + live.sourceRows.length + " streams=" + live.streamRows.length);
        }

        Timer {
            interval: 700
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_audio saved:", r.saveToFile("/tmp/opencode/preview_audio.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
