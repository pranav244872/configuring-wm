pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property list<Monitor> monitors: variants.instances

    function getActiveMonitor(): var {
        return monitors[0]; 
    }

    Variants {
        id: variants
        model: Quickshell.screens
        Monitor {}
    }

    component Monitor: QtObject {
        id: monitor
        required property ShellScreen modelData
        property real brightness: 0.5

        readonly property Process initProc: Process {
            command: ["sh", "-c", "echo $(brightnessctl g) $(brightnessctl m)"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    const parts = text.trim().split(" ");
                    if (parts.length >= 2) {
                        monitor.brightness = parseInt(parts[0]) / parseInt(parts[1]);
                    }
                }
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            brightness = value;
            const rounded = Math.round(value * 100);
            Quickshell.execDetached(["brightnessctl", "s", rounded + "%"]);
        }
    }
}
