pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string modId: "community.kde-connect-helper"
    readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("../../scripts/kde_connect_helper.py").toString().replace("file://", ""))

    property bool buttonVisible: true
    property string placement: "trailing"
    property string appearance: "compact"
    property string displayMode: "icon-status"
    property string preferredDevice: "auto"
    property string primaryClick: "popup"
    property string batteryDisplay: "outline"
    property int pollingInterval: 15
    property bool hideDisconnected: false
    property bool showPing: true
    property bool showRing: true
    property bool showFileShare: true
    property bool showTextShare: true
    property bool showStatusLabels: true
    property bool showTooltips: true
    property bool hideKdeConnectLabel: false
    property real ringThickness: 3
    property string ringColor: "#66bb6a"
    property int lowBatteryThreshold: 20
    property string lowBatteryColor: "#ef5350"

    property bool installed: false
    property bool daemonRunning: false
    property string cliExecutable: ""
    property string daemonExecutable: ""
    property string dbusExecutable: ""
    property string launcherKind: "none"
    property string launcherExecutable: ""
    property string autostartState: "unavailable"
    property string autostartMethod: "manual"
    property string autostartPath: ""
    property var devices: []
    property bool scanning: false
    property bool busy: false
    property string operation: ""
    property string messageCode: ""
    property bool messageError: false
    property var installPlan: ({})
    property bool installPlanBusy: false

    property int nextRequestId: 1
    property var activeRequest: null
    property var deferredRequest: null

    readonly property var pairedDevices: devices.filter(device => device.paired)
    readonly property var connectedDevices: pairedDevices.filter(device => device.reachable)
    readonly property var selectedDevice: {
        if (preferredDevice !== "auto") {
            const preferred = pairedDevices.find(device => device.id === preferredDevice);
            if (preferred)
                return preferred;
        }
        if (connectedDevices.length > 0)
            return connectedDevices[0];
        return pairedDevices.length > 0 ? pairedDevices[0] : null;
    }
    readonly property bool shouldShowButton: buttonVisible
        && (!hideDisconnected || connectedDevices.length > 0 || !installed || !daemonRunning)

    signal refreshed

    function applySetting(key, value) {
        switch (key) {
        case "buttonVisible": buttonVisible = !!value; break;
        case "placement": placement = String(value); break;
        case "appearance": appearance = String(value); break;
        case "displayMode": displayMode = String(value); break;
        case "preferredDevice": preferredDevice = String(value || "auto"); break;
        case "primaryClick": primaryClick = String(value); break;
        case "batteryDisplay": batteryDisplay = String(value); break;
        case "pollingInterval": pollingInterval = Math.max(5, Math.min(300, Number(value) || 15)); break;
        case "hideDisconnected": hideDisconnected = !!value; break;
        case "showPing": showPing = !!value; break;
        case "showRing": showRing = !!value; break;
        case "showFileShare": showFileShare = !!value; break;
        case "showTextShare": showTextShare = !!value; break;
        case "showStatusLabels": showStatusLabels = !!value; break;
        case "showTooltips": showTooltips = !!value; break;
        case "hideKdeConnectLabel": hideKdeConnectLabel = !!value; break;
        case "ringThickness": ringThickness = Math.max(1, Math.min(6, Number(value) || 3)); break;
        case "ringColor": ringColor = validColor(value, "#66bb6a"); break;
        case "lowBatteryThreshold": lowBatteryThreshold = Math.max(0, Math.min(50, Number(value) || 20)); break;
        case "lowBatteryColor": lowBatteryColor = validColor(value, "#ef5350"); break;
        }
    }

    function validColor(value, fallback) {
        const text = String(value ?? "");
        return /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(text) ? text : fallback;
    }

    function loadSettings() {
        ModsService.getSettings(modId, (result, error) => {
            if (error || !result)
                return;
            const values = result.values ?? ({});
            Object.keys(values).forEach(key => root.applySetting(key, values[key]));
        });
    }

    function setPreferredDevice(deviceId) {
        const next = deviceId || "auto";
        preferredDevice = next;
        ModsService.setSetting(modId, "preferredDevice", next);
    }

    function send(command, data, timeout) {
        if (activeRequest)
            return false;
        const request = Object.assign({}, data ?? ({}));
        request.id = nextRequestId++;
        request.command = command;
        activeRequest = request;
        operation = command;
        messageCode = "";
        messageError = false;
        busy = command !== "scan" && command !== "install_plan";
        scanning = command === "scan";
        installPlanBusy = command === "install_plan";
        requestTimeout.interval = timeout ?? 12000;
        requestTimeout.restart();
        if (bridge.running)
            bridge.write(JSON.stringify(request) + "\n");
        else {
            deferredRequest = request;
            bridge.running = true;
        }
        return true;
    }

    function refresh() {
        send("scan", {}, 10000);
    }

    function loadInstallPlan() {
        send("install_plan", {}, 8000);
    }

    function install() {
        if (installPlan.automatic)
            send("install", { family: installPlan.family }, 190000);
    }

    function startDaemon() {
        send("start_daemon", {}, 12000);
    }

    function openInterface() {
        send("open", {}, 12000);
    }

    function setAutostart(enabled) {
        send(enabled ? "enable_autostart" : "disable_autostart", {}, 15000);
    }

    function runAction(kind, extra) {
        if (!selectedDevice) {
            setMessage("no_selected_device", true);
            return;
        }
        const data = { kind: kind, deviceId: selectedDevice.id };
        if (kind === "share_file")
            data.path = String(extra ?? "");
        if (kind === "share_text")
            data.text = String(extra ?? "");
        send("action", data, 15000);
    }

    function setMessage(code, error) {
        messageCode = String(code || "operation_failed");
        messageError = !!error;
    }

    function applyScan(data) {
        installed = !!data.installed;
        daemonRunning = !!data.daemonRunning;
        cliExecutable = String(data.cli ?? "");
        daemonExecutable = String(data.daemon ?? "");
        dbusExecutable = String(data.qdbus ?? "");
        launcherKind = String(data.launcher?.kind ?? "none");
        launcherExecutable = String(data.launcher?.path ?? "");
        autostartState = String(data.autostart?.state ?? "unavailable");
        autostartMethod = String(data.autostart?.method ?? "manual");
        autostartPath = String(data.autostart?.path ?? "");
        devices = Array.isArray(data.devices) ? data.devices : [];
        refreshed();
    }

    function finishRequest(response) {
        if (!activeRequest || Number(response.id) !== Number(activeRequest.id))
            return;
        requestTimeout.stop();
        const command = activeRequest.command;
        activeRequest = null;
        scanning = false;
        installPlanBusy = false;
        busy = false;
        operation = "";
        if (!response.ok) {
            setMessage(response.code, true);
            return;
        }
        const data = response.data ?? ({});
        if (command === "scan") {
            applyScan(data);
            return;
        }
        if (command === "install_plan") {
            installPlan = data;
            return;
        }
        setMessage(response.code, false);
        delayedRefresh.restart();
    }

    function abortRequest(code) {
        requestTimeout.stop();
        activeRequest = null;
        deferredRequest = null;
        scanning = false;
        installPlanBusy = false;
        busy = false;
        operation = "";
        setMessage(code, true);
        if (bridge.running)
            bridge.signal(9);
        bridgeRestart.restart();
    }

    Component.onCompleted: {
        loadSettings();
        bridge.running = true;
        initialScan.restart();
    }

    Component.onDestruction: {
        requestTimeout.stop();
        bridge.running = false;
    }

    Connections {
        target: ModsService
        function onSettingChanged(changedModId, key, value) {
            if (changedModId === root.modId)
                root.applySetting(key, value);
        }
    }

    Timer { id: initialScan; interval: 250; onTriggered: root.refresh() }
    Timer { id: delayedRefresh; interval: 800; onTriggered: root.refresh() }
    Timer { id: bridgeRestart; interval: 300; onTriggered: bridge.running = true }
    Timer {
        id: pollTimer
        interval: root.pollingInterval * 1000
        repeat: true
        running: root.buttonVisible && root.installed && root.daemonRunning
        onTriggered: root.refresh()
    }
    Timer {
        id: requestTimeout
        onTriggered: root.abortRequest("operation_timeout")
    }

    Process {
        id: bridge
        command: ["python3", root.helperPath]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.finishRequest(JSON.parse(data));
                } catch (error) {
                    root.abortRequest("response_invalid");
                }
            }
        }
        stderr: SplitParser { onRead: data => {} }
        onStarted: {
            if (root.deferredRequest) {
                bridge.write(JSON.stringify(root.deferredRequest) + "\n");
                root.deferredRequest = null;
            }
        }
        onExited: {
            if (root.activeRequest)
                root.abortRequest("bridge_stopped");
        }
    }
}
