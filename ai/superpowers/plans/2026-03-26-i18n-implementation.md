# i18n Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full internationalization to Ambxst with English, Russian, and Spanish translations, automatic language detection, and a language selector in settings.

**Architecture:** Pure QML/JS translation system using a singleton `I18n.qml` that loads JSON translation files via FileView. Language auto-detected from system locale with manual override stored in Config. All hardcoded UI strings replaced with `I18n.t("key")` calls.

**Tech Stack:** QML, JavaScript, JSON, QuickShell FileView

---

### Task 1: Create translation files

**Files:**
- Create: `translations/languages.json`
- Create: `translations/en.json`

- [ ] **Step 1: Create `translations/languages.json`**

```json
{
    "en": "English",
    "ru": "Русский",
    "es": "Español"
}
```

- [ ] **Step 2: Create `translations/en.json` with all UI strings**

This file contains every user-visible string in the project organized by module. Keys use dot notation. Parameterized strings use `%1`, `%2` placeholders.

The full key set will be built incrementally during migration tasks (Tasks 5-11). Start with the complete English file containing all keys identified during exploration. The file will be ~300+ entries.

Structure:

```json
{
    "_meta.direction": "ltr",

    "common.search": "Search...",
    "common.open": "Open",
    "common.delete": "Delete",
    "common.save": "Save",
    "common.copy": "Copy",
    "common.copied": "Copied!",
    "common.remove": "Remove",
    "common.rename": "Rename",
    "common.back": "Back",
    "common.error": "Error",
    "common.active": "Active",
    "common.auto": "Auto",
    "common.reset_default": "Reset to default",
    "common.discard_changes": "Discard changes",
    "common.unsaved_changes": "Unsaved changes",
    "common.save_close": "Save & Close",
    "common.add": "Add",
    "common.cancel": "Cancel",
    "common.none": "None",
    "common.enabled": "Enabled",
    "common.disabled": "Disabled",
    "common.coming_soon": "Coming Soon",

    "settings.network": "Network",
    "settings.bluetooth": "Bluetooth",
    "settings.mixer": "Mixer",
    "settings.ai": "AI",
    "settings.effects": "Effects",
    "settings.theme": "Theme",
    "settings.binds": "Binds",
    "settings.system": "System",
    "settings.compositor": "Compositor",
    "settings.ambxst": "Ambxst",

    "settings.system.prefixes": "Prefixes",
    "settings.system.weather": "Weather",
    "settings.system.performance": "Performance",
    "settings.system.resources": "System Resources",
    "settings.system.idle": "Idle",
    "settings.system.language": "Language",

    "settings.theme.general": "General",
    "settings.theme.shadow": "Shadow",
    "settings.theme.colors": "Colors",
    "settings.theme.fonts": "Fonts",
    "settings.theme.ui_font": "UI Font",
    "settings.theme.mono_font": "Mono Font",
    "settings.theme.roundness": "Roundness",
    "settings.theme.animation": "Animation",
    "settings.theme.duration": "Duration",
    "settings.theme.tint_icons": "Tint Icons",
    "settings.theme.enable_corners": "Enable Corners",
    "settings.theme.variant": "Variant",
    "settings.theme.editor": "Editor",
    "settings.theme.wallpapers": "Wallpapers",

    "settings.shell.bar": "Bar",
    "settings.shell.sidebar": "Sidebar",
    "settings.shell.frame": "Frame",
    "settings.shell.notch": "Notch",
    "settings.shell.workspaces": "Workspaces",
    "settings.shell.overview": "Overview",
    "settings.shell.dock": "Dock",
    "settings.shell.lockscreen": "Lockscreen",
    "settings.shell.desktop": "Desktop",
    "settings.shell.system": "System",

    "bar.tooltip.controls": "Audio & Brightness Controls",
    "bar.tooltip.launcher": "Open Launcher",
    "bar.tooltip.overview": "Open Window Overview",
    "bar.tooltip.presets": "Open Presets Manager",
    "bar.tooltip.tools": "Tools",
    "bar.tooltip.pin_bar": "Pin bar",
    "bar.tooltip.unpin_bar": "Unpin bar",
    "bar.tooltip.pin_dock": "Pin dock",
    "bar.tooltip.unpin_dock": "Unpin dock",

    "battery.status": "Battery: %1%",
    "battery.charging": "Charging",
    "battery.full": "Full",
    "battery.fully_charged": "Fully charged",
    "battery.on_battery": "On battery",
    "battery.remaining": "%1 remaining",
    "battery.full_in": "Full in %1",
    "battery.power_profile": "Power Profile: %1",

    "bluetooth.disabled": "Bluetooth is disabled",
    "bluetooth.no_devices": "No devices found",
    "bluetooth.scan": "Scan for devices",
    "bluetooth.connecting": "Connecting...",
    "bluetooth.forget": "Forget",

    "wifi.disabled": "Wi-Fi is disabled",
    "wifi.no_networks": "No networks found",
    "wifi.rescan": "Rescan networks",
    "wifi.connecting": "Connecting...",
    "wifi.limited": "Limited",
    "wifi.password": "Enter password...",
    "wifi.open_portal": "Open captive portal",
    "wifi.band_5g": "5G",
    "wifi.tooltip_on": "Wi-Fi: On",
    "wifi.tooltip_off": "Wi-Fi: Off",

    "player.nothing_playing": "Nothing Playing",
    "player.enjoy_silence": "Enjoy the silence",
    "player.unknown": "Unknown",

    "controls.night_light_on": "Night Light: On",
    "controls.night_light_off": "Night Light: Off",
    "controls.caffeine_on": "Caffeine: On",
    "controls.caffeine_off": "Caffeine: Off",
    "controls.game_mode_on": "Game Mode: On",
    "controls.game_mode_off": "Game Mode: Off",

    "mixer.no_apps": "No applications using audio",
    "mixer.output": "Output",
    "mixer.input": "Input",

    "effects.not_installed": "EasyEffects not installed",
    "effects.output_presets": "Output Presets",
    "effects.input_presets": "Input Presets",

    "launcher.search": "Search applications...",

    "overview.search": "Search windows...",

    "clipboard.copying": "Copying!",

    "notes.search": "Search or create note...",

    "lockscreen.loading": "Loading desktop...",

    "pomodoro.work_session": "Work Session",
    "pomodoro.rest_session": "Rest Session",
    "pomodoro.stop_alarm": "STOP ALARM",
    "pomodoro.start_work": "START WORK",
    "pomodoro.start_rest": "START REST",
    "pomodoro.pause": "PAUSE",
    "pomodoro.resume": "RESUME",
    "pomodoro.minus_1m": "-1m",
    "pomodoro.plus_1m": "+1m",
    "pomodoro.sync_spotify": "Sync Spotify",

    "weather.location": "Location",
    "weather.location_placeholder": "e.g. Buenos Aires, Tokyo...",
    "weather.unit": "Unit",
    "weather.celsius": "Celsius",
    "weather.fahrenheit": "Fahrenheit",

    "idle.lock_cmd": "Command to lock screen",
    "idle.before_sleep": "Command before sleep",
    "idle.after_sleep": "Command after sleep",
    "idle.add_listener": "Add Listener",

    "performance.blur_transition": "Blur Transition",
    "performance.window_preview": "Window Preview",
    "performance.wavy_line": "Wavy Line",
    "performance.rotate_cover": "Rotate Cover Art",
    "performance.dashboard_persist": "Persist Dashboard Tabs",

    "presets.no_presets": "No presets configured",
    "presets.search": "Search or create preset...",

    "ai.search_models": "Search models...",
    "ai.enter_api_key": "Enter API Key...",
    "ai.ask_or_help": "Ask AI or type /help...",
    "ai.message": "Message AI...",
    "ai.run_command": "Run Command",
    "ai.approve": "Approve",
    "ai.reject": "Reject",
    "ai.command_approved": "Command Approved",
    "ai.command_rejected": "Command Rejected",
    "ai.custom_provider": "Custom Provider",
    "ai.chat_history": "Chat History",
    "ai.hello_user": "Hello, %1.",

    "desktop.open": "Open",
    "desktop.delete": "Delete",

    "system.disk_path_placeholder": "e.g. /, /home...",
    "system.add_disk": "Add Disk",

    "binds.add_key": "Add another key",
    "binds.add_action": "Add another action",
    "binds.key_configured": "Key Configured",
    "binds.not_configured": "Not Configured",
    "binds.keybind_name_placeholder": "e.g. Open Terminal, Switch to Workspace 1...",
    "binds.key_placeholder": "e.g. R, TAB, ESCAPE, mouse:272...",
    "binds.delete_keybind": "Delete keybind",

    "compositor.general": "General",
    "compositor.colors": "Colors",
    "compositor.shadows": "Shadows",
    "compositor.blur": "Blur",
    "compositor.coming_soon_text": "These are upcoming features. Settings here will expand as compositor integration improves.",

    "shell.show_keyboard_layout": "Show Keyboard Layout",
    "shell.show_audio_switcher": "Show Audio Device Switcher",
    "shell.excluded_sinks": "Excluded Audio Sinks",
    "shell.position": "Position",
    "shell.hover_reveal": "Hover to reveal",

    "theme.gradient_stops": "Gradient Stops",
    "theme.gradient_mode": "Gradient Mode",
    "theme.item_color": "Item Color",
    "theme.opacity": "Opacity",
    "theme.border": "Border",
    "theme.angle": "Angle",
    "theme.reset_gradient": "Reset Gradient",
    "theme.add_stop": "Add Stop",
    "theme.delete_stop": "Delete stop",
    "theme.color_picker": "Color picker",
    "theme.custom": "Custom",
    "theme.symbol_or_icon": "Symbol or path to icon...",

    "language.auto": "Auto",
    "language.auto_detected": "Auto (%1)"
}
```

NOTE: This is the starting set. Additional keys will be discovered and added during migration tasks as each file is reviewed. The key is to begin with this comprehensive base and extend as needed.

- [ ] **Step 3: Verify file is valid JSON**

Run: `python3 -c "import json; json.load(open('translations/en.json')); print('OK')"`
Expected: `OK`

---

### Task 2: Create I18n singleton

**Files:**
- Create: `modules/services/I18n.qml`

- [ ] **Step 1: Create `modules/services/I18n.qml`**

```qml
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

QtObject {
    id: root

    readonly property string configLanguage: Config.system?.language ?? "auto"
    property string resolvedLanguage: "en"
    property var strings: ({})
    property var fallback: ({})
    property var availableLanguages: ({})
    property bool ready: false

    function t(key) {
        let str = root.strings[key] ?? root.fallback[key] ?? key;
        for (let i = 1; i < arguments.length; i++)
            str = str.replace("%" + i, arguments[i]);
        return str;
    }

    function detectSystemLanguage() {
        const sources = [
            Qt.locale().name,
            Quickshell.env("LC_MESSAGES"),
            Quickshell.env("LC_ALL"),
            Quickshell.env("LANG")
        ];
        for (const src of sources) {
            if (src && src.length >= 2) {
                const code = src.substring(0, 2).toLowerCase();
                if (code !== "c" && code !== "po")
                    return code;
            }
        }
        return "en";
    }

    function resolveLanguage() {
        const lang = root.configLanguage === "auto"
            ? detectSystemLanguage()
            : root.configLanguage;

        if (root.availableLanguages[lang])
            return lang;
        return "en";
    }

    onConfigLanguageChanged: {
        root.resolvedLanguage = resolveLanguage();
    }

    FileView {
        id: languagesLoader
        path: Qt.resolvedUrl("../../translations/languages.json")
        preload: true
        onLoaded: {
            try {
                root.availableLanguages = JSON.parse(text());
                root.resolvedLanguage = root.resolveLanguage();
            } catch (e) {
                console.warn("I18n: failed to parse languages.json:", e);
                root.availableLanguages = { "en": "English" };
            }
        }
    }

    FileView {
        id: fallbackLoader
        path: Qt.resolvedUrl("../../translations/en.json")
        preload: true
        onLoaded: {
            try {
                root.fallback = JSON.parse(text());
                if (root.resolvedLanguage === "en") {
                    root.strings = root.fallback;
                    root.ready = true;
                }
            } catch (e) {
                console.warn("I18n: failed to parse en.json:", e);
            }
        }
    }

    FileView {
        id: langLoader
        path: root.resolvedLanguage !== "en"
              ? Qt.resolvedUrl("../../translations/" + root.resolvedLanguage + ".json")
              : ""
        onLoaded: {
            if (root.resolvedLanguage === "en") return;
            try {
                root.strings = JSON.parse(text());
                root.ready = true;
            } catch (e) {
                console.warn("I18n: failed to parse " + root.resolvedLanguage + ".json:", e);
                root.strings = root.fallback;
                root.ready = true;
            }
        }
    }

    onResolvedLanguageChanged: {
        if (resolvedLanguage === "en") {
            root.strings = root.fallback;
            root.ready = Object.keys(root.fallback).length > 0;
        } else {
            langLoader.reload();
        }
    }
}
```

- [ ] **Step 2: Verify the singleton is importable**

Check that the file has `pragma Singleton` and follows the same pattern as other services in `modules/services/`. No qmldir needed -- QuickShell auto-discovers singletons via `pragma Singleton`.

---

### Task 3: Add language config property

**Files:**
- Modify: `config/defaults/system.js:42-48`
- Modify: `config/Config.qml:943-949`

- [ ] **Step 1: Add language to system defaults**

In `config/defaults/system.js`, add `"language": "auto"` to the data object, after the pomodoro block:

```javascript
    "pomodoro": {
        "workTime": 1500,
        "restTime": 300,
        "autoStart": false,
        "syncSpotify": false
    },
    "language": "auto"
}
```

- [ ] **Step 2: Add language property to Config.qml systemLoader adapter**

In `config/Config.qml`, inside the `systemLoader` adapter block (after line 948, the closing brace of the pomodoro JsonObject):

```qml
            property JsonObject pomodoro: JsonObject {
                property int workTime: 1500
                property int restTime: 300
                property bool autoStart: false
                property bool syncSpotify: false
            }
            property string language: "auto"
        }
```

---

### Task 4: Add language selector to SystemPanel

**Files:**
- Modify: `modules/widgets/dashboard/controls/SystemPanel.qml:86,124-145`
- Modify: `modules/widgets/dashboard/controls/SettingsIndex.qml:107-112`

- [ ] **Step 1: Add import for I18n service**

At the top of `modules/widgets/dashboard/controls/SystemPanel.qml`, add to the imports (after line 9):

```qml
import qs.modules.services
```

- [ ] **Step 2: Add Language menu button**

In the menu section (after line 128, the Weather SectionButton), insert a new SectionButton:

```qml
                        SectionButton {
                            text: "Language"
                            sectionId: "language"
                        }
```

- [ ] **Step 3: Update titlebar to handle "language" sectionId**

The titlebar at line 86 auto-capitalizes sectionId, so "language" becomes "Language". However, "system" has a special case mapping to "System Resources". The current code already handles this correctly for "language" -- it will display "Language" via the default `.charAt(0).toUpperCase() + .slice(1)` fallback. No change needed.

- [ ] **Step 4: Add Language section content**

After the Idle section (find the last `}` of the idle ColumnLayout), add the Language section. Use the same chip-selector pattern as the Weather unit selector:

```qml
                    // =====================
                    // LANGUAGE SECTION
                    // =====================
                    ColumnLayout {
                        visible: root.currentSection === "language"
                        property string settingsSection: "language"
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Language"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.Medium
                            color: Colors.overSurfaceVariant
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            StyledRect {
                                id: autoButton

                                property bool isSelected: Config.system.language === "auto"
                                property bool isHovered: false

                                variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                                width: autoLabel.width + 24
                                height: 36
                                radius: Styling.radius(-2)

                                Text {
                                    id: autoLabel
                                    anchors.centerIn: parent
                                    text: {
                                        const detected = I18n.detectSystemLanguage();
                                        const name = I18n.availableLanguages[detected] ?? detected;
                                        return "Auto (" + name + ")";
                                    }
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: autoButton.isSelected ? Font.Bold : Font.Normal
                                    color: autoButton.item
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: autoButton.isHovered = true
                                    onExited: autoButton.isHovered = false
                                    onClicked: Config.system.language = "auto"
                                }
                            }

                            Repeater {
                                model: Object.keys(I18n.availableLanguages)

                                delegate: StyledRect {
                                    id: langButton
                                    required property string modelData

                                    property bool isSelected: Config.system.language === modelData
                                    property bool isHovered: false

                                    variant: isSelected ? "primary" : (isHovered ? "focus" : "common")
                                    width: langLabel.width + 24
                                    height: 36
                                    radius: Styling.radius(-2)

                                    Text {
                                        id: langLabel
                                        anchors.centerIn: parent
                                        text: I18n.availableLanguages[langButton.modelData] ?? langButton.modelData
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        font.weight: langButton.isSelected ? Font.Bold : Font.Normal
                                        color: langButton.item
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: langButton.isHovered = true
                                        onExited: langButton.isHovered = false
                                        onClicked: Config.system.language = langButton.modelData
                                    }
                                }
                            }
                        }
                    }
```

- [ ] **Step 5: Add Language entry to SettingsIndex**

In `modules/widgets/dashboard/controls/SettingsIndex.qml`, after the Weather entries (line 97), add:

```javascript
        // System > Language
        { label: "Language", keywords: "locale translation i18n localization lang", section: 6, subSection: "language", subLabel: "System > Language", icon: Icons.globe, isIcon: true },
```

- [ ] **Step 6: Test the language selector**

Launch the shell, open Settings > System, verify:
- "Language" button appears in the menu
- Clicking it shows the language selector section
- "Auto" chip shows detected language in parentheses
- Selecting a language updates `Config.system.language`
- Setting persists after restart

---

### Task 5: Create Russian translation

**Files:**
- Create: `translations/ru.json`

- [ ] **Step 1: Create `translations/ru.json`**

Copy `en.json`, translate all values to Russian. Keys remain identical. All ~300+ entries must be translated.

- [ ] **Step 2: Validate JSON**

Run: `python3 -c "import json; en=json.load(open('translations/en.json')); ru=json.load(open('translations/ru.json')); missing=[k for k in en if k not in ru]; print('Missing:', missing) if missing else print('OK')"`

---

### Task 6: Create Spanish translation

**Files:**
- Create: `translations/es.json`

- [ ] **Step 1: Create `translations/es.json`**

Copy `en.json`, translate all values to Spanish. Keys remain identical.

- [ ] **Step 2: Validate JSON**

Run: `python3 -c "import json; en=json.load(open('translations/en.json')); es=json.load(open('translations/es.json')); missing=[k for k in en if k not in es]; print('Missing:', missing) if missing else print('OK')"`

---

### Task 7: Migrate settings panel strings

**Files:**
- Modify: `modules/widgets/dashboard/controls/SettingsTab.qml` (section names in sectionModel)
- Modify: `modules/widgets/dashboard/controls/SystemPanel.qml` (all hardcoded strings)
- Modify: `modules/widgets/dashboard/controls/ThemePanel.qml`
- Modify: `modules/widgets/dashboard/controls/ShellPanel.qml`
- Modify: `modules/widgets/dashboard/controls/SettingsIndex.qml` (label and subLabel fields)

- [ ] **Step 1: Migrate SettingsTab section names**

In `SettingsTab.qml`, the `sectionModel` array has `name` fields. Replace each with `I18n.t()`:

```qml
{ name: I18n.t("settings.network"), icon: Icons.wifiHigh, ... }
{ name: I18n.t("settings.bluetooth"), icon: Icons.bluetooth, ... }
// etc for all 10 sections
```

Add `import qs.modules.services` to the file if not present.

- [ ] **Step 2: Migrate SystemPanel strings**

Replace all hardcoded strings in `SystemPanel.qml` with `I18n.t()` calls:

- Section titles: `"Prefixes"` -> `I18n.t("settings.system.prefixes")`
- Labels: `"Unit"` -> `I18n.t("weather.unit")`, `"Location"` -> `I18n.t("weather.location")`
- Placeholders: `"e.g. Buenos Aires, Tokyo..."` -> `I18n.t("weather.location_placeholder")`
- Button labels: `"Celsius"` -> `I18n.t("weather.celsius")`, `"Add Listener"` -> `I18n.t("idle.add_listener")`
- Tooltips: `"Back"` -> `I18n.t("common.back")`

- [ ] **Step 3: Migrate ThemePanel strings**

Replace all hardcoded strings: section headers, labels, tooltips, button texts.

- [ ] **Step 4: Migrate ShellPanel strings**

Replace all hardcoded strings: section buttons, toggle labels, tooltips.

- [ ] **Step 5: Migrate SettingsIndex labels**

Replace `label` and `subLabel` fields with `I18n.t()` calls. Leave `keywords` untranslated.

```javascript
{ label: I18n.t("settings.system.language"), keywords: "locale translation...", section: 6, subSection: "language", subLabel: I18n.t("settings.system") + " > " + I18n.t("settings.system.language"), icon: Icons.globe, isIcon: true },
```

- [ ] **Step 6: Discover and add any missing keys to en.json, ru.json, es.json**

During migration, new strings will be found. Add keys to all three translation files.

---

### Task 8: Migrate bar component strings

**Files:**
- Modify: `modules/bar/ControlsButton.qml`
- Modify: `modules/bar/BatteryIndicator.qml`
- Modify: `modules/bar/BarContent.qml`
- Modify: `modules/bar/clock/Clock.qml`
- Modify: `modules/bar/clock/Calendar.qml`
- Modify: `modules/bar/clock/Pomodoro.qml`
- Modify: `modules/bar/KeyboardLayoutIndicator.qml`
- Modify: `modules/bar/AudioDeviceSwitcher.qml`

- [ ] **Step 1: Migrate tooltip texts**

Replace `tooltipText: "..."` with `tooltipText: I18n.t("bar.tooltip.xxx")` in all bar components.

- [ ] **Step 2: Migrate BatteryIndicator strings**

Replace battery status strings: `"Charging"`, `"Full"`, `"On battery"`, parameterized `"Battery: X%"` etc.

- [ ] **Step 3: Migrate Pomodoro strings**

Replace: `"Work Session"`, `"Rest Session"`, `"STOP ALARM"`, `"START WORK"`, `"PAUSE"`, `"RESUME"`, etc.

- [ ] **Step 4: Migrate remaining bar strings**

Clock labels, calendar headers, AudioDeviceSwitcher labels, KeyboardLayoutIndicator tooltip.

- [ ] **Step 5: Add `import qs.modules.services` to each file that doesn't have it**

---

### Task 9: Migrate dashboard and widget strings

**Files:**
- Modify: `modules/widgets/dashboard/widgets/FullPlayer.qml`
- Modify: `modules/widgets/dashboard/widgets/QuickControls.qml`
- Modify: `modules/widgets/defaultview/CompactPlayer.qml`
- Modify: `modules/widgets/dashboard/DashboardContent.qml`
- Modify: `modules/widgets/dashboard/clipboard/ClipboardTab.qml`
- Modify: `modules/widgets/dashboard/notes/NotesTab.qml`
- Modify: `modules/widgets/dashboard/tmux/TmuxTab.qml`
- Modify: `modules/widgets/dashboard/wallpapers/WallpapersTab.qml`
- Modify: `modules/widgets/dashboard/metrics/MetricsTab.qml`

- [ ] **Step 1: Migrate player strings**

Replace: `"Nothing Playing"`, `"Enjoy the silence"`, `"Unknown"`.

- [ ] **Step 2: Migrate QuickControls tooltips**

Replace: Night Light, Caffeine, Game Mode toggle tooltips.

- [ ] **Step 3: Migrate tab-specific strings**

Clipboard: `"Copying!"`, `"Copied!"`, search placeholders.
Notes: search placeholder, buttons.
Tmux: session labels.
Wallpapers: buttons, labels.
Metrics: section headers.

---

### Task 10: Migrate Bluetooth, WiFi, Mixer, Effects panels

**Files:**
- Modify: `modules/widgets/dashboard/controls/BluetoothPanel.qml`
- Modify: `modules/widgets/dashboard/controls/WifiPanel.qml`
- Modify: `modules/widgets/dashboard/controls/AudioMixerPanel.qml`
- Modify: `modules/widgets/dashboard/controls/EasyEffectsPanel.qml`

- [ ] **Step 1: Migrate BluetoothPanel strings**

Replace: `"Bluetooth is disabled"`, `"No devices found"`, `"Scan for devices"`, `"Connecting..."`, `"Forget"`.

- [ ] **Step 2: Migrate WifiPanel strings**

Replace: `"Wi-Fi is disabled"`, `"No networks found"`, `"Rescan networks"`, `"Enter password..."`, `"Open captive portal"`.

- [ ] **Step 3: Migrate AudioMixerPanel strings**

Replace: `"No applications using audio"`, `"Output"`, `"Input"`, section headers.

- [ ] **Step 4: Migrate EasyEffectsPanel strings**

Replace: `"EasyEffects not installed"`, `"Output Presets"`, `"Input Presets"`.

---

### Task 11: Migrate remaining modules

**Files:**
- Modify: `modules/widgets/config/AiPanel.qml`
- Modify: `modules/sidebar/AssistantSidebar.qml`
- Modify: `modules/notifications/NotificationDelegate.qml`
- Modify: `modules/lockscreen/LockScreen.qml`
- Modify: `modules/widgets/launcher/Launcher.qml`
- Modify: `modules/widgets/overview/OverviewPopup.qml`
- Modify: `modules/widgets/presets/PresetsPopup.qml`
- Modify: `modules/desktop/DesktopIcons.qml` (if applicable)
- Modify: `modules/widgets/dashboard/controls/CompositorPanel.qml`
- Modify: `modules/widgets/dashboard/controls/BindsPanel.qml`

- [ ] **Step 1: Migrate AI panel and sidebar strings**

Replace: `"Search models..."`, `"Enter API Key..."`, `"Ask AI or type /help..."`, `"Run Command"`, `"Approve"`, `"Reject"`, `"Hello, %1."`.

- [ ] **Step 2: Migrate launcher and overview strings**

Replace: `"Search applications..."`, `"Search windows..."`.

- [ ] **Step 3: Migrate notifications, lockscreen, presets, desktop strings**

Replace remaining hardcoded strings in each file.

- [ ] **Step 4: Migrate compositor and binds panel strings**

Replace: `"Coming Soon"`, keybind labels, section headers.

- [ ] **Step 5: Final scan for missed strings**

Run: `grep -rn '"[A-Z][a-z]' modules/ --include="*.qml" | grep -v 'I18n\|import\|Icons\|font\|Icons\.\|property\|//\|Easing\|Image\|Text\.\|Font\.\|Config\.\|Colors\.\|Styling\.\|Qt\.\|anchors\|Behavior\|Animation\|Layout\|source:\|id:\|variant:\|Keys\.'`

Review output for any remaining hardcoded user-visible strings that were missed. Add them to all translation files and replace with `I18n.t()`.

---

### Task 12: Finalize and verify translations are complete

**Files:**
- Modify: `translations/en.json` (add any missing keys found during migration)
- Modify: `translations/ru.json` (sync with en.json)
- Modify: `translations/es.json` (sync with en.json)

- [ ] **Step 1: Validate all translation files have matching keys**

```bash
python3 -c "
import json
en = json.load(open('translations/en.json'))
for lang in ['ru', 'es']:
    other = json.load(open(f'translations/{lang}.json'))
    missing = [k for k in en if k not in other]
    extra = [k for k in other if k not in en]
    if missing: print(f'{lang}: missing {len(missing)} keys:', missing)
    if extra: print(f'{lang}: extra {len(extra)} keys:', extra)
    if not missing and not extra: print(f'{lang}: OK ({len(en)} keys)')
"
```

Expected: all languages report OK with matching key count.

- [ ] **Step 2: Test language switching**

Launch the shell and verify:
1. Default language detected correctly from system locale
2. Switch to Russian -- all visible strings change to Russian
3. Switch to Spanish -- all visible strings change to Spanish
4. Switch to Auto -- reverts to system language
5. No raw keys visible (no `"settings.network"` appearing in UI)
6. Parameterized strings render correctly (battery %, time remaining)
7. Settings persist after restart

- [ ] **Step 3: Test fallback behavior**

Temporarily rename `ru.json`, set language to Russian. Verify English fallback appears instead of raw keys.

---

### Task 13: Commit

- [ ] **Step 1: Stage and commit all changes**

```bash
git checkout -b feature/i18n
git add translations/ modules/services/I18n.qml config/defaults/system.js config/Config.qml modules/
git commit -m "feat: add i18n with English, Russian, and Spanish translations

Add internationalization system with automatic language detection from
system locale (Qt.locale, LC_MESSAGES, LC_ALL, LANG). Translation files
use JSON format for easy contribution of new languages.

New files:
- modules/services/I18n.qml: singleton with t() function and fallback
- translations/languages.json: registry of available languages
- translations/en.json, ru.json, es.json: translation files

All user-visible strings (~300+) replaced with I18n.t() calls.
Language selector added to Settings > System."
```
