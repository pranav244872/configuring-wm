// Dashboard audio tab: pavucontrol's three useful surfaces in one column --
// output picker, input picker with a live meter, and per-app streams.
//
// Master volume is written with wpctl, not node.audio: on a hardware-volume
// device (this USB headset) the node factor is not the level you hear. That is
// the same conclusion the OSD already documents (osd/OsdHost.qml), which is why
// both read/write through wpctl. App streams have no hardware volume, so they
// write node.audio directly.
//
// Only the visible tab tracks nodes; deactivate() drops the snapshots and the
// tracker so nothing listens in the background.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules
import qs.modules.widgets
import qs.modules.audio
import "audio_model.js" as Audio

Item {
    id: root

    // Bench hooks: when mock is set, PipeWire is never read.
    property bool mock: false
    property bool active: false
    property var mockSinkRows: []
    property var mockSourceRows: []
    property var mockStreamRows: []
    property real mockSinkVolume: 0.6
    property real mockSourceVolume: 1.0
    property bool mockSinkMuted: false
    property bool mockSourceMuted: false
    property real mockPeak: 0.4

    readonly property var sink: root.mock ? null : Pipewire.defaultAudioSink
    readonly property var source: root.mock ? null : Pipewire.defaultAudioSource

    // Rows are {id, name} snapshots; delegates resolve their node by that pair.
    property var sinkRows: []
    property var sourceRows: []
    property var streamRows: []
    property var trackedNodes: []

    readonly property real sinkVolume: root.mock ? root.mockSinkVolume
        : (root.sink && root.sink.audio ? root.sink.audio.volume : 0)
    readonly property bool sinkMuted: root.mock ? root.mockSinkMuted
        : (root.sink && root.sink.audio ? root.sink.audio.muted : false)
    readonly property real sourceVolume: root.mock ? root.mockSourceVolume
        : (root.source && root.source.audio ? root.source.audio.volume : 0)
    readonly property bool sourceMuted: root.mock ? root.mockSourceMuted
        : (root.source && root.source.audio ? root.source.audio.muted : false)

    readonly property string sinkKind: root.sink ? Audio.glyphFor(root.sink) : Theme.glyphs.audioSpeaker
    readonly property string sourceKind: root.source ? Audio.glyphFor(root.source) : Theme.glyphs.audioMic

    // ---------------------------------------------------------------- data
    function rebuild() {
        if (root.mock)
            return;
        const values = Pipewire.nodes && Pipewire.nodes.values ? Pipewire.nodes.values : [];
        root.sinkRows = Audio.rows(values, Audio.isSinkDevice);
        root.sourceRows = Audio.rows(values, Audio.isSourceDevice);
        root.streamRows = Audio.rows(values, Audio.isPlaybackStream);

        // node.audio is only valid while the node is tracked (see OsdHost).
        const tracked = [];
        for (let i = 0; i < values.length; i++) {
            const n = values[i];
            if (n && n.audio)
                tracked.push(n);
        }
        root.trackedNodes = tracked;
    }

    function nodeFor(row) {
        if (!row || root.mock)
            return null;
        const values = Pipewire.nodes && Pipewire.nodes.values ? Pipewire.nodes.values : [];
        for (let i = 0; i < values.length; i++) {
            const n = values[i];
            if (n && n.id === row.id && String(n.name) === row.name)
                return n;
        }
        return null;
    }

    // Which sink a playback stream feeds, from the link graph.
    function streamTarget(row) {
        if (!row || root.mock)
            return "";
        try {
            const groups = Pipewire.linkGroups && Pipewire.linkGroups.values ? Pipewire.linkGroups.values : [];
            for (let i = 0; i < groups.length; i++) {
                const g = groups[i];
                if (g && g.source && g.source.id === row.id && g.target)
                    return Audio.deviceLabel(g.target);
            }
        } catch (e) {
        }
        return "";
    }

    function activate() {
        root.active = true;
        root.rebuild();
    }

    function deactivate() {
        root.active = false;
        root.sinkRows = [];
        root.sourceRows = [];
        root.streamRows = [];
        root.trackedNodes = [];
    }

    // ------------------------------------------------------------ actions
    function setDefault(row, isSource) {
        if (root.mock)
            return;
        const node = root.nodeFor(row);
        if (!node)
            return;
        if (isSource)
            Pipewire.preferredDefaultAudioSource = node;
        else
            Pipewire.preferredDefaultAudioSink = node;
        // preferred* is a hint; confirm it became the actual default.
        defaultGuard.wantedId = node.id;
        defaultGuard.wantedName = String(node.name);
        defaultGuard.isSource = isSource;
        defaultGuard.restart();
    }

    function toggleMute(isSource) {
        if (root.mock)
            return;
        muteProc.command = ["wpctl", "set-mute",
                            isSource ? "@DEFAULT_AUDIO_SOURCE@" : "@DEFAULT_AUDIO_SINK@",
                            "toggle"];
        muteProc.running = true;
    }

    // Drags emit ~100 values/s: coalesce into one write per 50 ms and unmute,
    // the same rule as the volume keys and the OSD.
    property string writeTarget: "sink"
    property real writeValue: 0

    function queueVolume(isSource, value) {
        if (root.mock)
            return;
        root.writeTarget = isSource ? "source" : "sink";
        root.writeValue = value;
        volumeWrite.restart();
    }

    function flushVolume() {
        if (volumeProc.running) {
            volumeWrite.restart();
            return;
        }
        const target = root.writeTarget === "source" ? "@DEFAULT_AUDIO_SOURCE@" : "@DEFAULT_AUDIO_SINK@";
        const pct = Math.round(Math.max(0, Math.min(1, root.writeValue)) * 100);
        volumeProc.command = ["sh", "-c",
                              "wpctl set-mute " + target + " 0; " +
                              "wpctl set-volume -l 1 " + target + " " + pct + "%"];
        volumeProc.running = true;
    }

    // Slider draft: while dragging, the handle follows the pointer instead of
    // waiting for the write to round-trip.
    property bool sinkDragging: false
    property real sinkDraft: 0
    property bool sourceDragging: false
    property real sourceDraft: 0

    Timer {
        id: sinkSettle
        interval: 400
        onTriggered: root.sinkDragging = false
    }

    Timer {
        id: sourceSettle
        interval: 400
        onTriggered: root.sourceDragging = false
    }

    // -------------------------------------------------------- live wiring
    PwObjectTracker {
        objects: root.active ? root.trackedNodes : []
    }

    PwNodePeakMonitor {
        id: peak
        node: root.mock ? null : root.source
        enabled: root.active && !root.mock && !!root.source
    }

    readonly property real peakValue: root.mock ? root.mockPeak
        : (root.active && peak.enabled ? peak.peak : 0)

    Connections {
        target: root.mock ? null : Pipewire.nodes

        function onValuesChanged() { modelChanged.restart() }
        function onObjectInsertedPost() { modelChanged.restart() }
        function onObjectRemovedPost() { modelChanged.restart() }
    }

    Connections {
        target: root.mock ? null : Pipewire.linkGroups

        function onValuesChanged() { modelChanged.restart() }
    }

    Timer {
        id: modelChanged
        interval: 150
        onTriggered: root.rebuild()
    }

    Timer {
        id: volumeWrite
        interval: 50
        onTriggered: root.flushVolume()
    }

    Timer {
        id: defaultGuard
        interval: 700
        property int wantedId: -1
        property string wantedName: ""
        property bool isSource: false
        onTriggered: {
            if (root.mock)
                return;
            const current = defaultGuard.isSource ? Pipewire.defaultAudioSource : Pipewire.defaultAudioSink;
            if (current && current.id === defaultGuard.wantedId)
                return;
            fallbackProc.command = ["wpctl", "set-default", String(defaultGuard.wantedId)];
            fallbackProc.running = true;
        }
    }

    Process {
        id: volumeProc
    }

    Process {
        id: muteProc
    }

    Process {
        id: fallbackProc
    }

    // --------------------------------------------------------------- view
    component SectionHead: Item {
        id: head

        property string label: ""
        property string value: ""
        property string glyph: ""
        property color glyphColor: Theme.colors.subtext

        signal glyphClicked()

        implicitHeight: 26

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: head.label
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.subtext
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                text: head.value
                font.pixelSize: Theme.frame.labelSize
                font.letterSpacing: Theme.frame.tracking
                color: Theme.colors.primary
            }

            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                visible: head.glyph.length > 0

                StyledText {
                    anchors.centerIn: parent
                    text: head.glyph
                    font.family: Theme.font.icon
                    font.pixelSize: 17
                    color: headMa.containsMouse ? Theme.colors.primary : head.glyphColor
                }

                MouseArea {
                    id: headMa
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: head.glyphClicked()
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Theme.frame.line
            color: Theme.colors.outline
        }
    }

    component ListNote: StyledText {
        property string note: ""

        width: parent.width - 24
        x: 12
        topPadding: 6
        bottomPadding: 6
        text: note
        font.pixelSize: Theme.font.size.xs
        font.letterSpacing: Theme.frame.tracking
        color: Theme.colors.subtext
        opacity: 0.7
    }

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body

            width: flick.width
            spacing: 12

            // ------------------------------------------------------ output
            Column {
                width: parent.width
                spacing: 4

                SectionHead {
                    id: outputHead
                    width: parent.width
                    label: "OUTPUT"
                    value: Audio.percent(root.sinkDragging ? root.sinkDraft : root.sinkVolume)
                    glyph: Icons.output(root.sinkDragging ? root.sinkDraft : root.sinkVolume,
                                        root.sinkMuted, root.sinkKind)
                    glyphColor: root.sinkMuted ? Theme.colors.subtext : Theme.colors.fgLayer0
                    onGlyphClicked: root.toggleMute(false)
                }

                Slider {
                    id: sinkSlider
                    width: parent.width - 24
                    x: 12
                    value: root.sinkDragging ? root.sinkDraft : root.sinkVolume
                    interactive: !root.mock
                    opacity: root.sinkMuted ? 0.5 : 1

                    onSliderValueChanged: (value) => {
                        root.sinkDragging = true;
                        root.sinkDraft = value;
                        root.queueVolume(false, value);
                        sinkSettle.restart();
                    }
                    onSliderDragFinished: {
                        root.queueVolume(false, root.sinkDraft);
                        sinkSettle.restart();
                    }
                }

                Repeater {
                    model: root.mock ? root.mockSinkRows : root.sinkRows

                    delegate: AudioRow {
                        required property var modelData

                        width: body.width
                        row: modelData
                        node: root.nodeFor(modelData)
                        isDevice: true
                        current: modelData.current === true
                            || (root.sink && root.sink.id === modelData.id)
                        onActivated: root.setDefault(modelData, false)
                    }
                }

                ListNote {
                    visible: (root.mock ? root.mockSinkRows : root.sinkRows).length === 0
                    note: "NO OUTPUT DEVICES"
                }
            }

            Rectangle {
                width: parent.width - 24
                x: 12
                height: Theme.frame.line
                color: Theme.colors.outline
                opacity: 0.6
            }

            // ------------------------------------------------------- input
            Column {
                width: parent.width
                spacing: 4

                SectionHead {
                    width: parent.width
                    label: "INPUT"
                    value: Audio.percent(root.sourceDragging ? root.sourceDraft : root.sourceVolume)
                    glyph: Icons.input(root.sourceMuted, root.sourceKind)
                    glyphColor: root.sourceMuted ? Theme.colors.subtext : Theme.colors.fgLayer0
                    onGlyphClicked: root.toggleMute(true)
                }

                Slider {
                    width: parent.width - 24
                    x: 12
                    value: root.sourceDragging ? root.sourceDraft : root.sourceVolume
                    interactive: !root.mock
                    opacity: root.sourceMuted ? 0.5 : 1

                    onSliderValueChanged: (value) => {
                        root.sourceDragging = true;
                        root.sourceDraft = value;
                        root.queueVolume(true, value);
                        sourceSettle.restart();
                    }
                    onSliderDragFinished: {
                        root.queueVolume(true, root.sourceDraft);
                        sourceSettle.restart();
                    }
                }

                // Live level, pavucontrol's input meter: the node's peak while
                // the tab is visible only. The tinted track is the meter's own
                // ground so it cannot be mistaken for a second slider.
                Item {
                    width: parent.width - 24
                    x: 12
                    height: 7

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 3
                        color: ColorUtils.transparentize(Theme.colors.primary, 0.9)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        height: 3
                        width: parent.width * Math.max(0, Math.min(1, root.peakValue))
                        color: root.sourceMuted ? Theme.colors.subtext : Theme.colors.primary

                        Behavior on width {
                            NumberAnimation {
                                duration: 90
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                Repeater {
                    model: root.mock ? root.mockSourceRows : root.sourceRows

                    delegate: AudioRow {
                        required property var modelData

                        width: body.width
                        row: modelData
                        node: root.nodeFor(modelData)
                        isDevice: true
                        current: modelData.current === true
                            || (root.source && root.source.id === modelData.id)
                        onActivated: root.setDefault(modelData, true)
                    }
                }

                ListNote {
                    visible: (root.mock ? root.mockSourceRows : root.sourceRows).length === 0
                    note: "NO INPUT DEVICES"
                }
            }

            Rectangle {
                width: parent.width - 24
                x: 12
                height: Theme.frame.line
                color: Theme.colors.outline
                opacity: 0.6
            }

            // -------------------------------------------------------- apps
            Column {
                width: parent.width
                spacing: 2

                SectionHead {
                    width: parent.width
                    label: "APPS"
                    value: String((root.mock ? root.mockStreamRows : root.streamRows).length).padStart(2, "0")
                }

                Repeater {
                    model: root.mock ? root.mockStreamRows : root.streamRows

                    delegate: AudioRow {
                        required property var modelData

                        width: body.width
                        row: modelData
                        node: root.nodeFor(modelData)
                        isDevice: false
                        interactive: !root.mock
                        target: root.streamTarget(modelData) || String(modelData.target || "")

                        onMuteToggled: {
                            const n = root.nodeFor(modelData);
                            if (n && n.audio)
                                n.audio.muted = !n.audio.muted;
                        }
                        onVolumeMoved: (value) => {
                            const n = root.nodeFor(modelData);
                            if (n && n.audio)
                                n.audio.volume = Math.max(0, Math.min(1, value));
                        }
                    }
                }

                ListNote {
                    visible: (root.mock ? root.mockStreamRows : root.streamRows).length === 0
                    note: "NOTHING PLAYING"
                }
            }

            Item {
                width: parent.width
                height: 4
            }
        }
    }
}
