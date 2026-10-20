// Bluetooth bench: the six states of the tab over a mock desktop, no radio and
// no BlueZ process involved (the section never probes while `mock` is set).
// Saves /tmp/opencode/preview_bluetooth.png and quits.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.modules
import qs.modules.dashboard

ShellRoot {
    PanelWindow {
        id: win

        visible: true
        color: "#39434a"
        implicitWidth: 1860
        implicitHeight: 800

        component Sheet: Item {
            id: sheet

            property alias content: dashboardContent

            width: 600
            height: 380

            DashboardSurface {
                anchors.fill: parent
            }

            DashboardContent {
                id: dashboardContent
                anchors.fill: parent
                anchors.margins: Theme.frame.margins
                currentTab: 1
            }
        }

        // Mock devices. Plain objects: the row's d() guard reads them like a
        // live BluetoothDevice, and no method is ever called on them.
        readonly property var mockDevices: [
            {
                name: "WH-1000XM4",
                deviceName: "WH-1000XM4",
                address: "AC:80:0A:11:22:33",
                icon: "audio-headset",
                state: BluetoothDeviceState.Connected,
                connected: true,
                paired: true,
                pairing: false,
                trusted: true,
                batteryAvailable: true,
                battery: 0.87
            },
            {
                name: "MX Master 3",
                deviceName: "MX Master 3",
                address: "D4:3A:2C:55:66:77",
                icon: "input-mouse",
                state: BluetoothDeviceState.Disconnected,
                connected: false,
                paired: true,
                pairing: false,
                trusted: true,
                batteryAvailable: true,
                battery: 0.55
            },
            {
                name: "Keychron K3",
                deviceName: "Keychron K3",
                address: "C8:1B:6E:88:99:AA",
                icon: "input-keyboard",
                state: BluetoothDeviceState.Disconnected,
                connected: false,
                paired: true,
                pairing: false,
                trusted: true,
                batteryAvailable: false,
                battery: 0
            }
        ]

        readonly property var mockAvailable: [
            {
                name: "Pixel 8",
                deviceName: "Pixel 8",
                address: "9C:2F:9D:12:34:56",
                icon: "phone",
                state: BluetoothDeviceState.Disconnected,
                connected: false,
                paired: false,
                pairing: false,
                trusted: false,
                batteryAvailable: false,
                battery: 0
            },
            {
                name: "",
                deviceName: "",
                address: "00:1A:7D:DA:71:13",
                icon: "",
                state: BluetoothDeviceState.Disconnected,
                connected: false,
                paired: false,
                pairing: false,
                trusted: false,
                batteryAvailable: false,
                battery: 0
            }
        ]

        function adapterOn(enabled, discovering) {
            return {
                name: "arch",
                enabled: enabled,
                discovering: discovering,
                discoverable: false,
                state: enabled ? BluetoothAdapterState.Enabled : BluetoothAdapterState.Disabled
            };
        }

        Grid {
            id: scene
            anchors.centerIn: parent
            columns: 3
            spacing: 18

            // 1. on, saved devices, the connected one expanded
            Sheet {
                id: savedSheet
            }

            // 2. on, a discovered device expanded (PAIR / FORGET)
            Sheet {
                id: pairSheet
            }

            // 3. powered off
            Sheet {
                id: offSheet
            }

            // 4. rfkill soft block (Blueberry's "Bluetooth is disabled")
            Sheet {
                id: blockedSheet
            }

            // 5. on, nothing found yet
            Sheet {
                id: emptySheet
            }

            // 6. no adapter at all
            Sheet {
                id: absentSheet
            }
        }

        Component.onCompleted: {
            const saved = savedSheet.content.bluetooth;
            saved.mock = true;
            saved.mockAdapter = win.adapterOn(true, true);
            saved.mockDevices = win.mockDevices;
            saved.activate();
            saved.expandedAddress = "AC:80:0A:11:22:33";

            const pairing = pairSheet.content.bluetooth;
            pairing.mock = true;
            pairing.mockAdapter = win.adapterOn(true, true);
            pairing.mockDevices = win.mockAvailable;
            pairing.activate();
            pairing.expandedAddress = "9C:2F:9D:12:34:56";

            const off = offSheet.content.bluetooth;
            off.mock = true;
            off.mockAdapter = win.adapterOn(false, false);
            off.activate();

            const blocked = blockedSheet.content.bluetooth;
            blocked.mock = true;
            blocked.mockAdapter = {
                name: "arch",
                enabled: false,
                discovering: false,
                discoverable: false,
                state: BluetoothAdapterState.Blocked
            };
            blocked.mockRfkill = { soft: true, hard: false };
            blocked.activate();

            const empty = emptySheet.content.bluetooth;
            empty.mock = true;
            empty.mockAdapter = win.adapterOn(true, true);
            empty.activate();

            const absent = absentSheet.content.bluetooth;
            absent.mock = true;
            absent.mockAdapter = null;
            absent.activate();
        }

        Timer {
            interval: 700
            running: true
            onTriggered: scene.grabToImage(function (r) {
                console.log("preview_bluetooth saved:", r.saveToFile("/tmp/opencode/preview_bluetooth.png"));
                Qt.callLater(function () {
                    Qt.quit();
                });
            })
        }
    }
}
