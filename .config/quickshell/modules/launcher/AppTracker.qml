// App tracker singleton: persists app launch frequencies and sorts applications.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var frequencies: ({})
    property int cacheVersion: 0

    // Load frequencies on startup
    readonly property Process loader: Process {
        command: ["sh", "-c", "cat ~/.cache/quickshell/app_frequencies.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.frequencies = JSON.parse(text) || {};
                    root.cacheVersion++;
                } catch (e) {
                    root.frequencies = {};
                }
            }
        }
        Component.onCompleted: running = true
    }

    readonly property Process writer: Process {
        id: procWriter
    }

    function recordLaunch(appId) {
        if (!appId) return;
        const current = root.frequencies[appId] || 0;
        root.frequencies[appId] = current + 1;
        root.cacheVersion++;

        const jsonStr = JSON.stringify(root.frequencies);
        procWriter.command = ["sh", "-c", `mkdir -p ~/.cache/quickshell && echo '${jsonStr}' > ~/.cache/quickshell/app_frequencies.json`];
        procWriter.running = true;
    }

    function getFilteredApps(search) {
        const _ = root.cacheVersion;
        const all = DesktopEntries.applications?.values ?? [];
        const clean = all.filter(a => a && !a.noDisplay && (a.name?.length ?? 0) > 0);

        let filtered = clean;
        const query = (search || "").trim().toLowerCase();
        if (query.length > 0) {
            filtered = clean.filter(a => {
                const name = (a.name || "").toLowerCase();
                const gen = (a.genericName || "").toLowerCase();
                const com = (a.comment || "").toLowerCase();
                const cats = Array.isArray(a.categories) ? a.categories.join(" ").toLowerCase() : "";
                return name.includes(query) || gen.includes(query) || com.includes(query) || cats.includes(query);
            });
        }

        return filtered.sort((a, b) => {
            const freqA = root.frequencies[a.id] || 0;
            const freqB = root.frequencies[b.id] || 0;
            if (freqA !== freqB) {
                return freqB - freqA;
            }
            return String(a.name || "").localeCompare(String(b.name || ""));
        });
    }
}
