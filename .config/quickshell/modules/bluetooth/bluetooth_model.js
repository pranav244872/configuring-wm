// Bluetooth list helpers. Pure JS so the bench can feed plain objects.
//
// No QML enums in here: connection-state comparisons live in the row where
// BluetoothDeviceState is in scope. Everything below only touches booleans and
// strings, which is also what the membership signature needs.

const MAC_RE = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;

// BlueZ icon name -> [glyph, type label]. BlueZ reports names like
// "audio-headset", "input-mouse", "phone"; anything unknown falls back to the
// generic bluetooth glyph. Same idea as caelestia's Icons.getBluetoothIcon.
const RULES = [
    [["headset", "headphone"], "headphones", "HEADPHONES"],
    [["speaker", "audio"], "speaker", "SPEAKER"],
    [["mouse"], "mouse", "MOUSE"],
    [["keyboard"], "keyboard", "KEYBOARD"],
    [["gamepad", "joystick"], "sports_esports", "GAMEPAD"],
    [["phone"], "smartphone", "PHONE"],
    [["computer"], "computer", "COMPUTER"],
    [["watch"], "watch", "WATCH"],
    [["video", "tv"], "tv", "DISPLAY"],
    [["printer"], "print", "PRINTER"],
];

function rule(icon) {
    const i = String(icon || "").toLowerCase();
    for (const [keys, glyph, label] of RULES) {
        if (keys.some(k => i.indexOf(k) >= 0))
            return { glyph, label };
    }
    return { glyph: "bluetooth", label: "DEVICE" };
}

function glyph(icon) {
    return rule(icon).glyph;
}

function typeLabel(icon) {
    return rule(icon).label;
}

function isMacName(name) {
    return MAC_RE.test(String(name || ""));
}

function label(dev) {
    if (!dev)
        return "";
    const name = String(dev.name || dev.deviceName || "").trim();
    return name.length > 0 ? name : String(dev.address || "UNKNOWN");
}

// Connected first, then paired, then unpaired; inside a group prefer real names
// over bare MACs, then alphabetical. Matches what end-4 sorts for its bar.
function sorted(devices) {
    return [...(devices || [])].filter(d => d).sort((a, b) => {
        if (!!a.connected !== !!b.connected)
            return a.connected ? -1 : 1;
        if (!!a.paired !== !!b.paired)
            return a.paired ? -1 : 1;
        const aMac = isMacName(label(a));
        const bMac = isMacName(label(b));
        if (aMac !== bMac)
            return aMac ? 1 : -1;
        return label(a).localeCompare(label(b));
    });
}

// Membership/order fingerprint. A rebuild only runs when this changes, so a
// live state tick never resets delegates mid-interaction (same rule the
// network list follows).
function signature(devices) {
    return sorted(devices)
        .map(d => `${d.address}|${d.connected ? 1 : 0}|${d.paired ? 1 : 0}`)
        .join(",");
}

// Flat rows: section headers interleaved with devices, ready for the ListView.
function rows(devices) {
    const list = sorted(devices);
    const mine = list.filter(d => d.paired || d.connected);
    const available = list.filter(d => !d.paired && !d.connected);
    const out = [];

    if (mine.length > 0) {
        out.push({ kind: "header", label: "MY DEVICES", count: mine.length });
        for (const dev of mine)
            out.push({ kind: "device", dev });
    }
    if (available.length > 0) {
        out.push({ kind: "header", label: "AVAILABLE", count: available.length });
        for (const dev of available)
            out.push({ kind: "device", dev });
    }
    return out;
}

// "87%" or "" when the device does not report a battery.
// Quickshell's battery is 0..1 (BlueZ's percentage scaled by 0.01).
function batteryText(dev) {
    if (!dev || !dev.batteryAvailable)
        return "";
    const level = Math.round(Number(dev.battery || 0) * 100);
    return level > 0 ? level + "%" : "";
}
