// Network list helpers. Pure data/logic only: enum comparisons stay in the QML
// (where Quickshell.Networking is imported) and glyph names stay in Theme.
//
// API notes: quickshell already dedupes access points per SSID (nm/wireless.cpp)
// and exposes WifiNetwork.signalStrength as 0.0 - 1.0 (strength / 100).

// Sort rank: connected first, then connecting, then saved, then the rest.
function rank(net) {
    if (net.connected)
        return 0;
    if (net.stateChanging)
        return 1;
    if (net.known)
        return 2;
    return 3;
}

function sortNetworks(list) {
    // Drop dead wrappers: NM deletes a network object when its AP disappears,
    // which can leave a null in a snapshot taken just before.
    return [...list].filter(n => n).sort((a, b) => rank(a) - rank(b) || b.signalStrength - a.signalStrength);
}

// 0 = none .. 4 = full; the caller maps this to a glyph.
function signalLevel(strength) {
    if (strength >= 0.75)
        return 4;
    if (strength >= 0.50)
        return 3;
    if (strength >= 0.25)
        return 2;
    if (strength > 0)
        return 1;
    return 0;
}

// Passphrase rules ported from plasma-nm's applet PasswordField: WEP takes
// 5/13 characters or 10/26 hex digits, everything else 8-64 characters.
function isValidPsk(wep, text) {
    if (wep)
        return /^(?:.{5}|[0-9a-fA-F]{10}|.{13}|[0-9a-fA-F]{26})$/.test(text);
    return /^(?:.{8,64})$/.test(text);
}

// True when two snapshots list the same SSIDs in the same order. Used to keep
// the list's model identity stable: handing the view an identical-but-new array
// still resets its delegates (and drops focus mid-edit).
function sameOrder(a, b) {
    if (a.length !== b.length)
        return false;
    for (let i = 0; i < a.length; i++)
        if (a[i].name !== b[i].name)
            return false;
    return true;
}
