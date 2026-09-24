pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    required property var bar
    property bool vertical: bar.orientation === "vertical"
    property bool layerEnabled: true
    property real startRadius: Styling.radius(0)
    property real endRadius: Styling.radius(0)
    property var pendingFiles: []
    property string confirmAction: ""
    property int installStep: 0

    readonly property var device: KdeConnectService.selectedDevice
    readonly property bool showPercent: KdeConnectService.batteryDisplay === "percentage"
        || KdeConnectService.batteryDisplay === "percentage-outline"
    readonly property bool showRing: KdeConnectService.batteryDisplay === "outline"
        || KdeConnectService.batteryDisplay === "percentage-outline"
    readonly property bool hasBattery: !!device?.hasBattery
    readonly property string statusKey: {
        if (!KdeConnectService.installed)
            return "not_installed";
        if (!KdeConnectService.daemonRunning)
            return "daemon_stopped";
        if (KdeConnectService.pairedDevices.length === 0)
            return "no_paired_devices";
        if (KdeConnectService.connectedDevices.length === 0)
            return "offline";
        if (KdeConnectService.connectedDevices.length > 1)
            return "connected_count";
        return "connected";
    }
    readonly property string statusText: statusKey === "connected_count"
        ? I18n.t("kde_connect_helper.status.connected_count", KdeConnectService.connectedDevices.length)
        : I18n.t("kde_connect_helper.status." + statusKey)
    readonly property string batteryPercentage: hasBattery
        ? Math.round(device.battery) + "%" : ""
    readonly property bool batteryGlyphIsPercentage: KdeConnectService.displayMode === "battery"
        && showPercent && batteryPercentage.length > 0
    readonly property string mainGlyph: batteryGlyphIsPercentage
        ? batteryPercentage
        : (KdeConnectService.displayMode === "battery" ? Icons.lightning : Icons.deviceMobile)
    readonly property string selectedContent: {
        if (KdeConnectService.displayMode === "icon-device")
            return device?.name ?? I18n.t("kde_connect_helper.no_device");
        if (KdeConnectService.displayMode === "icon-status")
            return statusText;
        if (KdeConnectService.displayMode === "battery")
            return "";
        return "";
    }
    readonly property string detailedContent: {
        if (KdeConnectService.displayMode === "battery" && device) {
            return device.name;
        }
        if (selectedContent.length > 0 && showPercent && batteryPercentage.length > 0)
            return selectedContent + " · " + batteryPercentage;
        return selectedContent;
    }
    readonly property bool expandedButton: !vertical
        && KdeConnectService.appearance === "detailed"
        && KdeConnectService.displayMode !== "icon-only"
        && detailedContent.length > 0
    readonly property string buttonLabel: {
        if (expandedButton)
            return detailedContent;
        if (!vertical && KdeConnectService.appearance === "compact"
                && KdeConnectService.displayMode !== "icon-only"
                && KdeConnectService.displayMode !== "battery")
            return selectedContent;
        return "";
    }
    readonly property bool compactLabel: !expandedButton && buttonLabel.length > 0

    implicitWidth: vertical ? 36 : (expandedButton ? 148 : (compactLabel ? 112 : 36))
    implicitHeight: 36
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    visible: KdeConnectService.shouldShowButton

    function openPrimary() {
        if (!KdeConnectService.installed || KdeConnectService.primaryClick === "popup") {
            helperPopup.toggle();
            if (!KdeConnectService.installed) {
                root.installStep = 0;
                KdeConnectService.loadInstallPlan();
                installModal.visible = true;
            }
        } else {
            KdeConnectService.openInterface();
        }
    }

    function launcherText() {
        const key = KdeConnectService.launcherKind || "none";
        return I18n.t("kde_connect_helper.launcher." + key);
    }

    function autostartText() {
        return I18n.t("kde_connect_helper.autostart." + KdeConnectService.autostartState);
    }

    function planValue(value) {
        const text = String(value ?? "");
        return text.length > 0 && text !== "unknown" ? text : I18n.t("kde_connect_helper.unknown");
    }

    function installMethodText() {
        const method = String(KdeConnectService.installPlan.method ?? "manual");
        return I18n.t("kde_connect_helper.install_method." + method);
    }

    function unsupportedActions() {
        if (!device || !device.reachable)
            return "";
        const actions = [];
        if (KdeConnectService.showPing && !device.supportsPing)
            actions.push(I18n.t("kde_connect_helper.ping"));
        if (KdeConnectService.showRing && !device.supportsRing)
            actions.push(I18n.t("kde_connect_helper.ring"));
        if (KdeConnectService.showFileShare && !device.supportsShare)
            actions.push(I18n.t("kde_connect_helper.send_file"));
        if (KdeConnectService.showTextShare && !device.supportsText)
            actions.push(I18n.t("kde_connect_helper.share_text"));
        return actions.join(", ");
    }

    component HelperButton: Button {
        id: control
        property string iconText: ""
        property string labelText: ""
        property bool danger: false
        implicitHeight: 36
        leftPadding: 10
        rightPadding: 10
        activeFocusOnTab: true
        Accessible.name: labelText
        background: StyledRect {
            id: helperButtonBackground
            variant: control.down || control.checked ? "primary" : (control.hovered || control.activeFocus ? "focus" : "common")
            radius: Styling.radius(-4)
            enableShadow: false
        }
        contentItem: RowLayout {
            spacing: 7
            Text {
                visible: control.iconText.length > 0
                text: control.iconText
                font.family: Icons.font
                font.pixelSize: 16
                color: helperButtonBackground.item
            }
            Text {
                Layout.fillWidth: true
                text: control.labelText
                color: control.danger ? Colors.red : helperButtonBackground.item
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Button {
        id: barButton
        anchors.fill: parent
        hoverEnabled: true
        activeFocusOnTab: true
        Accessible.name: I18n.t("kde_connect_helper.accessible.button")
        Accessible.description: root.statusText
        onClicked: root.openPrimary()

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        background: StyledRect {
            id: buttonBackground
            variant: helperPopup.isOpen ? "primary" : "bg"
            enableShadow: root.layerEnabled
            topLeftRadius: root.vertical ? root.startRadius : root.startRadius
            topRightRadius: root.vertical ? root.startRadius : root.endRadius
            bottomLeftRadius: root.vertical ? root.endRadius : root.startRadius
            bottomRightRadius: root.vertical ? root.endRadius : root.endRadius

            Rectangle {
                anchors.fill: parent
                color: Styling.srItem("overprimary")
                opacity: helperPopup.isOpen ? 0
                    : (barButton.down ? 0.5 : (barButton.hovered || barButton.activeFocus ? 0.25 : 0))
                radius: parent.radius ?? 0

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 2 }
                }
            }

            Canvas {
                id: batteryCanvas
                anchors.fill: parent
                visible: root.showRing && root.hasBattery
                antialiasing: true
                z: 2

                function appendArc(points, centerX, centerY, radius, startAngle, endAngle) {
                    if (radius <= 0) {
                        points.push({ x: centerX, y: centerY });
                        return;
                    }
                    const steps = 8;
                    for (let step = 1; step <= steps; step++) {
                        const angle = startAngle + (endAngle - startAngle) * step / steps;
                        points.push({
                            x: centerX + Math.cos(angle) * radius,
                            y: centerY + Math.sin(angle) * radius
                        });
                    }
                }

                function buttonOutlinePoints(inset, topLeft, topRight, bottomRight, bottomLeft) {
                    const left = inset;
                    const top = inset;
                    const right = width - inset;
                    const bottom = height - inset;
                    const maxRadius = Math.min((right - left) / 2, (bottom - top) / 2);
                    const tl = Math.max(0, Math.min(topLeft - inset, maxRadius));
                    const tr = Math.max(0, Math.min(topRight - inset, maxRadius));
                    const br = Math.max(0, Math.min(bottomRight - inset, maxRadius));
                    const bl = Math.max(0, Math.min(bottomLeft - inset, maxRadius));
                    const points = [{ x: (left + right) / 2, y: top }, { x: right - tr, y: top }];
                    appendArc(points, right - tr, top + tr, tr, -Math.PI / 2, 0);
                    points.push({ x: right, y: bottom - br });
                    appendArc(points, right - br, bottom - br, br, 0, Math.PI / 2);
                    points.push({ x: left + bl, y: bottom });
                    appendArc(points, left + bl, bottom - bl, bl, Math.PI / 2, Math.PI);
                    points.push({ x: left, y: top + tl });
                    appendArc(points, left + tl, top + tl, tl, Math.PI, Math.PI * 1.5);
                    points.push({ x: (left + right) / 2, y: top });
                    return points;
                }

                function strokeFraction(context, points, fraction) {
                    let total = 0;
                    for (let index = 1; index < points.length; index++)
                        total += Math.hypot(points[index].x - points[index - 1].x,
                            points[index].y - points[index - 1].y);
                    let remaining = total * Math.max(0, Math.min(1, fraction));
                    context.beginPath();
                    context.moveTo(points[0].x, points[0].y);
                    for (let index = 1; index < points.length && remaining > 0; index++) {
                        const previous = points[index - 1];
                        const current = points[index];
                        const length = Math.hypot(current.x - previous.x, current.y - previous.y);
                        if (remaining >= length) {
                            context.lineTo(current.x, current.y);
                            remaining -= length;
                        } else {
                            const ratio = length > 0 ? remaining / length : 0;
                            context.lineTo(previous.x + (current.x - previous.x) * ratio,
                                previous.y + (current.y - previous.y) * ratio);
                            remaining = 0;
                        }
                    }
                    context.stroke();
                }

                onPaint: {
                    const context = getContext("2d");
                    context.reset();
                    const thickness = KdeConnectService.ringThickness;
                    const inset = thickness / 2;
                    const topLeft = buttonBackground.topLeftRadius;
                    const topRight = buttonBackground.topRightRadius;
                    const bottomRight = buttonBackground.bottomRightRadius;
                    const bottomLeft = buttonBackground.bottomLeftRadius;
                    const value = Math.max(0, Math.min(100, root.device?.battery ?? 0));
                    const points = buttonOutlinePoints(inset, topLeft, topRight, bottomRight, bottomLeft);
                    context.lineWidth = thickness;
                    context.lineCap = "round";
                    context.lineJoin = "round";
                    context.strokeStyle = Colors.outlineVariant;
                    strokeFraction(context, points, 1);
                    context.strokeStyle = value <= KdeConnectService.lowBatteryThreshold
                        ? KdeConnectService.lowBatteryColor
                        : (value <= KdeConnectService.warningBatteryThreshold
                            ? KdeConnectService.warningBatteryColor : KdeConnectService.ringColor);
                    strokeFraction(context, points, value / 100);
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                Connections {
                    target: KdeConnectService
                    function onSelectedDeviceChanged() { batteryCanvas.requestPaint(); }
                    function onRingThicknessChanged() { batteryCanvas.requestPaint(); }
                    function onRingColorChanged() { batteryCanvas.requestPaint(); }
                    function onLowBatteryThresholdChanged() { batteryCanvas.requestPaint(); }
                    function onLowBatteryColorChanged() { batteryCanvas.requestPaint(); }
                    function onWarningBatteryThresholdChanged() { batteryCanvas.requestPaint(); }
                    function onWarningBatteryColorChanged() { batteryCanvas.requestPaint(); }
                }
            }
        }

        contentItem: RowLayout {
            anchors.centerIn: parent
            spacing: 5

            Item {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30

                Text {
                    anchors.centerIn: parent
                    text: root.mainGlyph
                    font.family: root.batteryGlyphIsPercentage ? Styling.defaultFont : Icons.font
                    font.pixelSize: root.batteryGlyphIsPercentage ? Styling.fontSize(-2) : 17
                    font.bold: root.batteryGlyphIsPercentage
                    color: helperPopup.isOpen ? buttonBackground.item : Styling.srItem("overprimary")

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation { duration: Config.animDuration / 2 }
                    }
                }
            }

            Text {
                visible: root.buttonLabel.length > 0
                Layout.preferredWidth: root.expandedButton ? 105 : 72
                text: root.buttonLabel
                color: helperPopup.isOpen ? buttonBackground.item : Styling.srItem("overprimary")
                font.family: Styling.defaultFont
                font.pixelSize: Styling.fontSize(-1)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                    enabled: Config.animDuration > 0
                    ColorAnimation { duration: Config.animDuration / 2 }
                }
            }
        }

        StyledToolTip {
            show: KdeConnectService.showTooltips && barButton.hovered && !helperPopup.isOpen
            tooltipText: I18n.t("kde_connect_helper.title")
            desciription: root.statusText
        }
    }

    BarPopup {
        id: helperPopup
        anchorItem: buttonBackground
        bar: root.bar
        contentWidth: Math.max(280, Math.min(336, (root.bar?.screen?.width ?? 384) - 48))
        contentHeight: installModal.visible
            ? Math.max(320, Math.min(390, (root.bar?.screen?.height ?? 454) - 64))
            : Math.max(320, Math.min(486, (root.bar?.screen?.height ?? 550) - 64))
        closeOnFocusLost: KdeConnectService.operation !== "choose_files"
        onIsOpenChanged: {
            if (isOpen)
                Qt.callLater(() => refreshButton.forceActiveFocus());
            else
                Qt.callLater(() => barButton.forceActiveFocus());
        }

        Flickable {
            id: scrollArea
            anchors.fill: parent
            contentWidth: width
            contentHeight: popupColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            enabled: !installModal.visible && !confirmModal.visible
            visible: enabled
            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: popupColumn
                width: scrollArea.width - 6
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        text: Icons.deviceMobile
                        font.family: Icons.font
                        font.pixelSize: 22
                        color: Colors.overBackground
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: I18n.t("kde_connect_helper.title")
                            color: Colors.overBackground
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(1)
                            font.bold: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.statusText
                            color: Colors.overBackground
                            opacity: 0.72
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                            wrapMode: Text.Wrap
                        }
                    }
                    BusyIndicator {
                        running: KdeConnectService.scanning || KdeConnectService.busy
                        visible: running
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: statusColumn.implicitHeight + 20
                    variant: "common"
                    radius: Styling.radius(0)
                    enableShadow: false
                    ColumnLayout {
                        id: statusColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("kde_connect_helper.installed_status", KdeConnectService.installed
                                ? I18n.t("kde_connect_helper.yes") : I18n.t("kde_connect_helper.no"))
                            color: Colors.overBackground
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: I18n.t("kde_connect_helper.daemon_status", KdeConnectService.daemonRunning
                                ? I18n.t("kde_connect_helper.running") : I18n.t("kde_connect_helper.stopped"))
                            color: Colors.overBackground
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    HelperButton {
                        id: refreshButton
                        Layout.fillWidth: true
                        iconText: Icons.sync
                        labelText: I18n.t("kde_connect_helper.refresh")
                        enabled: !KdeConnectService.activeRequest
                        onClicked: KdeConnectService.refresh()
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        iconText: Icons.arrowSquareOut
                        labelText: I18n.t("kde_connect_helper.open_interface")
                        enabled: KdeConnectService.launcherExecutable.length > 0 && !KdeConnectService.activeRequest
                        onClicked: KdeConnectService.openInterface()
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: KdeConnectService.installed
                    text: I18n.t("kde_connect_helper.interface_available", root.launcherText())
                    color: Colors.overBackground
                    opacity: 0.65
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-2)
                    wrapMode: Text.Wrap
                }

                HelperButton {
                    Layout.fillWidth: true
                    visible: KdeConnectService.installed && !KdeConnectService.daemonRunning
                    iconText: Icons.play
                    labelText: I18n.t("kde_connect_helper.start_daemon")
                    enabled: KdeConnectService.daemonExecutable.length > 0 && !KdeConnectService.activeRequest
                    onClicked: KdeConnectService.startDaemon()
                }

                Text {
                    Layout.fillWidth: true
                    visible: KdeConnectService.installed && !KdeConnectService.daemonRunning
                        && KdeConnectService.daemonExecutable.length === 0
                    text: I18n.t("kde_connect_helper.message.daemon_executable_missing")
                    color: Colors.overBackground
                    opacity: 0.65
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-2)
                    wrapMode: Text.Wrap
                }

                HelperButton {
                    Layout.fillWidth: true
                    visible: !KdeConnectService.installed
                    iconText: Icons.arrowFatLinesDown
                    labelText: I18n.t("kde_connect_helper.installation_options")
                    enabled: !KdeConnectService.activeRequest
                    onClicked: {
                        root.installStep = 0;
                        KdeConnectService.loadInstallPlan();
                        installModal.visible = true;
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: KdeConnectService.installed && KdeConnectService.pairedDevices.length === 0
                    text: I18n.t("kde_connect_helper.pairing_hint")
                    color: Colors.overBackground
                    opacity: 0.76
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-1)
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: KdeConnectService.pairedDevices.length > 0
                    spacing: 5
                    Text {
                        text: I18n.t("kde_connect_helper.devices")
                        color: Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        font.bold: true
                    }
                    Repeater {
                        model: KdeConnectService.pairedDevices
                        delegate: HelperButton {
                            required property var modelData
                            Layout.fillWidth: true
                            iconText: modelData.reachable ? Icons.deviceMobile : Icons.alert
                            labelText: modelData.name + "  " + I18n.t("kde_connect_helper.device."
                                + (modelData.reachable ? "connected" : "offline"))
                            checked: KdeConnectService.selectedDevice?.id === modelData.id
                            onClicked: KdeConnectService.setPreferredDevice(modelData.id)
                        }
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        labelText: I18n.t("kde_connect_helper.automatic_device")
                        visible: KdeConnectService.preferredDevice !== "auto"
                        onClicked: KdeConnectService.setPreferredDevice("auto")
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: deviceColumn.implicitHeight + 20
                    visible: !!root.device
                    variant: "common"
                    radius: Styling.radius(0)
                    enableShadow: false
                    ColumnLayout {
                        id: deviceColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4
                        Text {
                            Layout.fillWidth: true
                            text: root.device?.name ?? ""
                            color: Colors.overBackground
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(0)
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: KdeConnectService.showStatusLabels
                            text: root.device?.reachable ? I18n.t("kde_connect_helper.device.connected")
                                : I18n.t("kde_connect_helper.device.offline")
                            color: Colors.overBackground
                            opacity: 0.72
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.hasBattery
                                ? I18n.t("kde_connect_helper.battery_value", Math.round(root.device.battery),
                                    root.device.charging ? I18n.t("kde_connect_helper.charging") : "")
                                : I18n.t("kde_connect_helper.battery_unavailable")
                            color: Colors.overBackground
                            opacity: 0.72
                            font.family: Styling.defaultFont
                            font.pixelSize: Styling.fontSize(-1)
                        }
                    }
                }

                Text {
                    visible: !!root.device
                    text: I18n.t("kde_connect_helper.quick_actions")
                    color: Colors.overBackground
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-1)
                    font.bold: true
                }
                GridLayout {
                    Layout.fillWidth: true
                    visible: !!root.device
                    columns: 2
                    columnSpacing: 6
                    rowSpacing: 6
                    HelperButton {
                        Layout.fillWidth: true
                        visible: KdeConnectService.showPing
                        iconText: Icons.paperPlane
                        labelText: I18n.t("kde_connect_helper.ping")
                        enabled: !!root.device?.reachable && !!root.device?.supportsPing && !KdeConnectService.activeRequest
                        onClicked: KdeConnectService.runAction("ping")
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        visible: KdeConnectService.showRing
                        iconText: Icons.bellRinging
                        labelText: I18n.t("kde_connect_helper.ring")
                        enabled: !!root.device?.reachable && !!root.device?.supportsRing && !KdeConnectService.activeRequest
                        onClicked: KdeConnectService.runAction("ring")
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        visible: KdeConnectService.showFileShare
                        iconText: Icons.file
                        labelText: I18n.t("kde_connect_helper.send_file")
                        enabled: !!root.device?.reachable && !!root.device?.supportsShare && !KdeConnectService.activeRequest
                        onClicked: KdeConnectService.chooseFiles(I18n.t("kde_connect_helper.choose_file"))
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        visible: KdeConnectService.showTextShare
                        iconText: Icons.clip
                        labelText: I18n.t("kde_connect_helper.share_text")
                        enabled: !!root.device?.reachable && !!root.device?.supportsText && !KdeConnectService.activeRequest
                        onClicked: textPanel.visible = !textPanel.visible
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: !!root.device && (!root.device.reachable || root.unsupportedActions().length > 0)
                    text: !root.device?.reachable ? I18n.t("kde_connect_helper.actions_offline_reason")
                        : I18n.t("kde_connect_helper.unsupported_actions", root.unsupportedActions())
                    color: Colors.overBackground
                    opacity: 0.65
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-2)
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    id: textPanel
                    Layout.fillWidth: true
                    visible: false
                    spacing: 5
                    TextArea {
                        id: shareText
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        placeholderText: I18n.t("kde_connect_helper.text_placeholder")
                        wrapMode: TextEdit.Wrap
                        onTextChanged: {
                            if (length > 4096)
                                remove(4096, length);
                        }
                        Accessible.name: I18n.t("kde_connect_helper.text_placeholder")
                        background: StyledRect { variant: "common"; radius: Styling.radius(-4); enableShadow: false }
                        color: Colors.overBackground
                    }
                    HelperButton {
                        Layout.fillWidth: true
                        labelText: I18n.t("kde_connect_helper.review_and_share")
                        enabled: shareText.text.trim().length > 0 && !KdeConnectService.activeRequest
                        onClicked: {
                            root.confirmAction = "text";
                            confirmModal.visible = true;
                        }
                    }
                }

                Text {
                    text: I18n.t("kde_connect_helper.autostart_title")
                    color: Colors.overBackground
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-1)
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    text: root.autostartText()
                    color: Colors.overBackground
                    opacity: 0.76
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-1)
                    wrapMode: Text.Wrap
                }
                Text {
                    Layout.fillWidth: true
                    visible: KdeConnectService.autostartPath.length > 0
                    text: I18n.t("kde_connect_helper.autostart_path", KdeConnectService.autostartPath)
                    color: Colors.overBackground
                    opacity: 0.58
                    font.family: Styling.defaultFont
                    font.pixelSize: Styling.fontSize(-2)
                    elide: Text.ElideMiddle
                }
                HelperButton {
                    Layout.fillWidth: true
                    visible: KdeConnectService.installed
                    iconText: KdeConnectService.autostartState === "enabled" ? Icons.cancel : Icons.accept
                    labelText: KdeConnectService.autostartState === "enabled"
                        ? I18n.t("kde_connect_helper.disable_autostart")
                        : I18n.t("kde_connect_helper.enable_autostart")
                    enabled: !KdeConnectService.activeRequest && KdeConnectService.autostartState !== "unavailable"
                    onClicked: KdeConnectService.setAutostart(KdeConnectService.autostartState !== "enabled")
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: messageLabel.implicitHeight + 16
                    visible: KdeConnectService.messageCode.length > 0
                    variant: "common"
                    radius: Styling.radius(-4)
                    enableShadow: false
                    Text {
                        id: messageLabel
                        anchors.fill: parent
                        anchors.margins: 8
                        text: I18n.t("kde_connect_helper.message." + KdeConnectService.messageCode)
                        color: KdeConnectService.messageError ? Colors.red : Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        Item {
            id: installModal
            anchors.fill: parent
            z: 20
            visible: false
            focus: visible
            onVisibleChanged: {
                if (visible)
                    Qt.callLater(() => installCancel.forceActiveFocus());
                else if (helperPopup.isOpen)
                    Qt.callLater(() => refreshButton.forceActiveFocus());
            }
            Keys.onEscapePressed: visible = false
            Rectangle { anchors.fill: parent; color: Colors.scrim; opacity: 0.55 }
            StyledRect {
                id: installCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 20, 310)
                height: Math.min(parent.height - 16, installColumn.implicitHeight + 24)
                variant: "popup"
                radius: Styling.radius(4)
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: width
                    contentHeight: installColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {}
                    ColumnLayout {
                        id: installColumn
                        width: parent.width - 6
                        spacing: 7
                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("kde_connect_helper.install_title")
                        color: Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(1)
                        font.bold: true
                        wrapMode: Text.Wrap
                    }
                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        visible: KdeConnectService.installPlanBusy || KdeConnectService.operation === "install"
                        running: visible
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !KdeConnectService.installPlanBusy
                        text: I18n.t("kde_connect_helper.install_summary",
                            root.planValue(KdeConnectService.installPlan.distribution),
                            root.planValue(KdeConnectService.installPlan.manager),
                            root.planValue(KdeConnectService.installPlan.package),
                            root.installMethodText())
                        color: Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !KdeConnectService.installPlanBusy
                        text: KdeConnectService.installPlan.pkexec
                            ? I18n.t("kde_connect_helper.pkexec_detected")
                            : I18n.t("kde_connect_helper.pkexec_not_detected")
                        color: Colors.overBackground
                        opacity: 0.76
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !KdeConnectService.installPlanBusy
                        text: KdeConnectService.installPlan.automatic
                            ? I18n.t("kde_connect_helper.pkexec_available")
                            : I18n.t("kde_connect_helper.automatic_unavailable")
                        color: Colors.overBackground
                        opacity: 0.76
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        wrapMode: Text.Wrap
                    }
                    TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 62
                        visible: !KdeConnectService.installPlan.automatic && (KdeConnectService.installPlan.command ?? "").length > 0
                        readOnly: true
                        selectByMouse: true
                        text: KdeConnectService.installPlan.command ?? ""
                        wrapMode: TextEdit.WrapAnywhere
                        Accessible.name: I18n.t("kde_connect_helper.manual_instruction")
                        background: StyledRect { variant: "common"; radius: Styling.radius(-4); enableShadow: false }
                        color: Colors.overBackground
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: KdeConnectService.installPlan.family === "nixos"
                        text: I18n.t("kde_connect_helper.nixos_note")
                        color: Colors.overBackground
                        opacity: 0.76
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.installStep === 1
                        text: I18n.t("kde_connect_helper.install_confirmation")
                        color: Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(-1)
                        font.bold: true
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        HelperButton {
                            id: installCancel
                            Layout.fillWidth: true
                            labelText: I18n.t("kde_connect_helper.cancel")
                            onClicked: installModal.visible = false
                        }
                        HelperButton {
                            Layout.fillWidth: true
                            visible: !!KdeConnectService.installPlan.automatic
                            labelText: root.installStep === 0 ? I18n.t("kde_connect_helper.continue")
                                : I18n.t("kde_connect_helper.install_now")
                            enabled: !KdeConnectService.activeRequest
                            onClicked: {
                                if (root.installStep === 0)
                                    root.installStep = 1;
                                else
                                    KdeConnectService.install();
                            }
                        }
                    }
                    }
                }
            }
        }

        Item {
            id: confirmModal
            anchors.fill: parent
            z: 21
            visible: false
            focus: visible
            onVisibleChanged: {
                if (visible)
                    Qt.callLater(() => confirmCancel.forceActiveFocus());
                else if (helperPopup.isOpen)
                    Qt.callLater(() => refreshButton.forceActiveFocus());
            }
            Keys.onEscapePressed: visible = false
            Rectangle { anchors.fill: parent; color: Colors.scrim; opacity: 0.55 }
            StyledRect {
                anchors.centerIn: parent
                width: Math.min(parent.width - 20, 300)
                implicitHeight: confirmColumn.implicitHeight + 24
                variant: "popup"
                radius: Styling.radius(4)
                ColumnLayout {
                    id: confirmColumn
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10
                    Text {
                        Layout.fillWidth: true
                        text: root.confirmAction === "file" ? I18n.t("kde_connect_helper.confirm_file")
                            : I18n.t("kde_connect_helper.confirm_text")
                        color: Colors.overBackground
                        font.family: Styling.defaultFont
                        font.pixelSize: Styling.fontSize(0)
                        font.bold: true
                        wrapMode: Text.Wrap
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        HelperButton {
                            id: confirmCancel
                            Layout.fillWidth: true
                            labelText: I18n.t("kde_connect_helper.cancel")
                            onClicked: confirmModal.visible = false
                        }
                        HelperButton {
                            Layout.fillWidth: true
                            labelText: I18n.t("kde_connect_helper.send")
                            enabled: !KdeConnectService.activeRequest
                            onClicked: {
                                if (root.confirmAction === "file")
                                    KdeConnectService.runAction("share_files", root.pendingFiles);
                                else {
                                    KdeConnectService.runAction("share_text", shareText.text);
                                    shareText.clear();
                                    textPanel.visible = false;
                                }
                                confirmModal.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: KdeConnectService
        function onFilesChosen(paths) {
            root.pendingFiles = paths;
            root.confirmAction = "file";
            if (!helperPopup.isOpen)
                helperPopup.open();
            confirmModal.visible = true;
        }
    }

    Connections {
        target: KdeConnectService
        function onInstalledChanged() {
            if (KdeConnectService.installed)
                installModal.visible = false;
        }
    }
}
