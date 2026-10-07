pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root
    readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("../../scripts/ocr_text_selection.py").toString().replace("file://", ""))
    property var queue: []
    property var activeRequest: null
    property var response: null
    property string responseError: ""

    function call(command, params, callback, capturedCallback) {
        queue.push({params: Object.assign({}, params, {command: command}), callback: callback, captured: capturedCallback});
        if (!activeRequest) Qt.callLater(root.startNext);
    }

    function startNext() {
        if (activeRequest || !queue.length) return;
        activeRequest = queue.shift();
        response = null;
        responseError = "";
        worker.running = true;
    }

    property Process worker: Process {
        command: ["python3", root.helperPath]
        stdinEnabled: true
        onStarted: {
            worker.write(JSON.stringify(root.activeRequest.params) + "\n");
            timeout.restart();
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    var message = JSON.parse(data);
                    if (message.event === "captured") {
                        if (root.activeRequest && root.activeRequest.captured) root.activeRequest.captured();
                    } else {
                        root.response = message.result || null;
                        root.responseError = message.error || "";
                    }
                } catch (error) {
                    root.responseError = "Invalid OCR response";
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            timeout.stop();
            var request = root.activeRequest;
            var result = root.response;
            var error = root.responseError || (exitCode !== 0 || !result ? (worker.stderr.text || "OCR helper stopped") : "");
            root.activeRequest = null;
            if (request && request.callback) request.callback(result, error || null);
            Qt.callLater(root.startNext);
        }
    }

    property Timer timeout: Timer {
        interval: 90000
        onTriggered: {
            root.responseError = "OCR operation timed out";
            worker.running = false;
        }
    }
}
