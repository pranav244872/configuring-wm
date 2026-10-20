// Audio tab helpers. Pure JS so the bench can feed plain rows.
//
// The section rebuilds rows as {id, name} snapshots after every graph change:
// a delegate holding a live PwNode hands Qt a QObject that PipeWire may delete
// out from under it (omarchy's panel documents the segfault on exactly that).
// Id + name is the identity, because PipeWire reuses ids.
//
// No Theme access in here -- glyphs are Material *ligature names*, like
// bluetooth_model.js.

function isSinkDevice(node) {
    return !!node && node.isSink === true && node.isStream !== true && !!node.audio;
}

function isSourceDevice(node) {
    return !!node && node.isSink !== true && node.isStream !== true && !!node.audio;
}

// Quickshell types a playback stream as a stream sink: isStream && isSink
// (verified here: Firefox id 74, type 21). Capture streams are stream sources.
function isPlaybackStream(node) {
    return !!node && node.isStream === true && node.isSink === true && !!node.audio;
}

function row(node) {
    if (!node || node.id === undefined || node.id === null)
        return null;
    return { id: node.id, name: String(node.name || "") };
}

function rows(list, keep) {
    const out = [];
    const values = list || [];
    for (let i = 0; i < values.length; i++) {
        const n = values[i];
        if (!n || !keep(n))
            continue;
        const r = row(n);
        if (r)
            out.push(r);
    }
    return out;
}

// PwNode.properties is invalid until the node is bound; reading it early
// destabilised omarchy's shell. Guard on ready.
function props(node) {
    try {
        return node && node.ready && node.properties ? node.properties : {};
    } catch (e) {
        return {};
    }
}

const SUFFIX = [
    /\s+Analog Stereo$/i,
    /\s+Digital Stereo(\s+.*)?$/i,
    /\s+Output$/i,
    /\s+Input$/i,
];

// "Blackwire C3220 Headset Analog Stereo" -> "Blackwire C3220 Headset".
function friendly(text) {
    let s = String(text || "").trim();
    for (const re of SUFFIX)
        s = s.replace(re, "");
    return s.trim();
}

// Device rows show the description (`wpctl status` does the same); nickname is
// truncated by WirePlumber on our headset ("... Seri"), so it is the fallback.
function deviceLabel(node) {
    if (!node)
        return "";
    const desc = friendly(node.description);
    if (desc)
        return desc;
    return friendly(node.nickname || props(node)["node.nick"] || node.name);
}

function streamLabel(node) {
    if (!node)
        return "";
    const p = props(node);
    return String(p["application.name"] || p["media.name"] || node.description || node.name || "");
}

function blob(node) {
    const p = props(node);
    return [node && node.name, node && node.description, node && node.nickname,
            p["device.icon-name"], p["device.product.name"]].join(" ").toLowerCase();
}

function glyphFor(node) {
    if (!node)
        return "speaker";
    const b = blob(node);
    if (/headset|headphone|earbud|airpod/.test(b))
        return "headphones";
    if (/bluetooth/.test(b))
        return "bluetooth_audio";
    if (/hdmi|display|monitor/.test(b))
        return "tv";
    if (/webcam|camera|v4l2/.test(b))
        return "videocam";
    return node.isSink ? "speaker" : "mic";
}

function streamGlyph(node) {
    const p = props(node);
    const b = String([p["application.name"], p["media.name"], node && node.description].join(" ")).toLowerCase();
    if (/record|mic|capture/.test(b))
        return "mic";
    return "graphic_eq";
}

// Device order is PipeWire's (stable); the list is short enough that sorting
// would only make rows jump when a device is added.
function percent(volume) {
    const v = Number(volume);
    if (!isFinite(v))
        return "0%";
    return Math.round(Math.max(0, Math.min(1.5, v)) * 100) + "%";
}
