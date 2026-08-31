# Task 3b — Batched cleanup report

Worktree: `~/ambxst-v2`, branch `local/all-features-v2`.
Commit: `ac8f9e08a32bfdf5244f13b5321ddf28d62b62f3`

## Item 1 — Russian OCR toggle no-op

`modules/services/Screenshot.qml`, `function ocrLangs()` (around line 259-275) was
missing a branch for `cfg.rus`. Added, matching the exact style of the neighbouring
opt-in languages, placed after the `kor` branch (last in the existing sequence):

```qml
if (cfg.chi_tra === true) langs.push("chi_tra");
if (cfg.kor === true) langs.push("kor");
if (cfg.rus === true) langs.push("rus");
```

### Toggle/branch audit (report only, no other edits made)

Checked all seven opt-in OCR languages (`lat`, `jpn`, `chi_sim`, `chi_tra`, `kor`,
plus `rus`, and the two default-on ones `eng`/`spa`) across four layers:

| lang    | Config.qml property (`config/Config.qml` ~1042-1050) | default (`config/defaults/system.js` ~33-42) | UI checkbox (`ShellPanel.qml`) | i18n label key (`translations/en.json`) | `ocrLangs()` branch |
|---------|:---:|:---:|:---:|:---:|:---:|
| eng     | yes | true  | yes (`shell.system.ocr_english`) | yes | yes |
| spa     | yes | true  | yes (`shell.system.ocr_spanish`) | yes | yes |
| lat     | yes | false | yes (`shell.system.ocr_latin`) | yes | yes |
| jpn     | yes | false | yes (`shell.system.ocr_japanese`) | yes | yes |
| chi_sim | yes | false | yes (`shell.system.ocr_chinese_simplified`) | yes | yes |
| chi_tra | yes | false | yes (`shell.system.ocr_chinese_traditional`) | yes | yes |
| kor     | yes | false | yes (`shell.system.ocr_korean`) | yes | yes |
| rus     | yes | false | yes (`shell.system.ocr_russian`) | yes | **fixed this task** |

Result: every toggle already had a matching Config property, default, UI checkbox
(`ShellPanel.qml` lines ~1886-1978) and translation key. The **only** mismatch in
either direction was the missing `rus` branch in `ocrLangs()`, now fixed. No other
toggle/branch mismatches found.

## Item 2 — Weather forecast day names

`modules/services/WeatherService.qml` (~lines 436-441) built forecast day names
from the two-letter `calendar.day.*` keys (`"calendar.day.mon": "Mo"`), which are
meant for the calendar column headers, not the forecast row (which upstream
previously rendered as three letters via `Qt.locale()`).

Added a dedicated `weather.day.sun` … `weather.day.sat` key set to
`translations/en.json`, `translations/ru.json`, `translations/es.json` (inserted
alphabetically after `weather.celsius`, before `weather.fahrenheit`, matching
existing sort order and indentation):

- en: Sun, Mon, Tue, Wed, Thu, Fri, Sat
- ru: Вс, Пн, Вт, Ср, Чт, Пт, Сб
- es: Dom, Lun, Mar, Mié, Jue, Vie, Sáb

`dayKeys` array in `WeatherService.qml` switched from `calendar.day.*` to
`weather.day.*`. The `calendar.day.*` keys themselves were left untouched — still
used by the calendar header.

## Item 3 — Battery tooltip hardcoded parentheses

Checked `battery.status` in `translations/en.json` first: `"Battery: %1%"` — it
already includes the percent sign and a "Battery:" prefix, no separate percent
literal used elsewhere in the string.

Added `battery.status_charging` to all three files, consistent with that phrasing:

- en: `"battery.status_charging": "Battery: %1% (%2)"`
- ru: `"battery.status_charging": "Батарея: %1% (%2)"`
- es: `"battery.status_charging": "Batería: %1% (%2)"`

`modules/bar/BatteryIndicator.qml` line 189 simplified from string concatenation
to a straight ternary between the two translation keys:

```qml
tooltipText: Battery.available
    ? (Battery.isCharging
        ? I18n.t("battery.status_charging", Math.round(Battery.percentage), I18n.t("battery.charging"))
        : I18n.t("battery.status", Math.round(Battery.percentage)))
    : I18n.t("battery.power_profile", PowerProfileClient.getProfileDisplayName(PowerProfileClient.currentProfile))
```

(shown reformatted here for readability; actual line is a single line as required
by the surrounding style)

## Verification

`qml-check.sh` output:

```
PASS: only the expected offscreen backend failure
```

JSON validity + key counts:

```
en: 759
ru: 759
es: 759
```

All three equal — files valid and in sync.

## Files touched

- `modules/services/Screenshot.qml`
- `modules/services/WeatherService.qml`
- `modules/bar/BatteryIndicator.qml`
- `translations/en.json`
- `translations/ru.json`
- `translations/es.json`

No forbidden files touched (`I18n.qml`, `AudioDeviceSwitcher.qml`,
`KeyboardLayoutService.qml`, `CompactPlayer.qml`, `FullPlayer.qml` — verified via
`git diff --name-only` against the forbidden list before committing).

One commit made: `ac8f9e08a32bfdf5244f13b5321ddf28d62b62f3`.
