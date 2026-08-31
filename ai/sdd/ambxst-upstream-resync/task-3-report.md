# Task 3: Merge upstream — Report

## Summary

Merged `origin/main` (110 upstream commits) into `local/all-features-v2` at base commit
`c78f2a11`. The conflict set git actually reported matched the predicted eight files
exactly, though one of the eight (`modules/services/PowerProfile.qml`) surfaced as a
modify/delete conflict rather than the content conflict the brief's resolution rule
assumed — handled as described below. All eight files resolved, `qml-check.sh` passes,
merge committed as `33de0589f7725154930ab0219c12c686d9b1fb59`.

## Conflicting files: predicted vs actual

Predicted (from `git merge-tree`, in brief):
```
config/Config.qml
config/defaults/system.js
modules/bar/BatteryIndicator.qml
modules/services/PowerProfile.qml
modules/services/SystemResources.qml
modules/services/WeatherService.qml
modules/widgets/dashboard/widgets/QuickControls.qml
modules/widgets/tools/ToolsMenu.qml
```

Actual (`git diff --name-only --diff-filter=U` after `git merge origin/main`):
```
config/Config.qml
config/defaults/system.js
modules/bar/BatteryIndicator.qml
modules/services/PowerProfile.qml
modules/services/SystemResources.qml
modules/services/WeatherService.qml
modules/widgets/dashboard/widgets/QuickControls.qml
modules/widgets/tools/ToolsMenu.qml
```

Identical sets — no files outside the predicted eight conflicted. The one deviation from
the brief's assumptions: `modules/services/PowerProfile.qml` was reported by git as a
**modify/delete** conflict ("deleted by them"), not a content conflict. Upstream deleted
the file entirely, replacing it with a new `modules/services/PowerProfileClient.qml`
(a `BackendService`-subscription-based singleton, part of a broader upstream migration
of several services — night light, caffeine, game mode, power profile, system resources,
weather — from ad-hoc Python/bash `Process` scripts to a Go backend daemon accessed via
`BackendService`). Every other file in the tree that referenced the old `PowerProfile`
symbol had already been auto-merged to reference `PowerProfileClient` instead, confirming
the rename/replacement was consistent and complete upstream. I treated this as in-scope
for the file's listed resolution rule (re-apply our I18n wrapping on top of upstream's
current code) rather than a re-scoping trigger, since the file is still in the predicted
list and the fix is mechanical.

## Resolution per file

**`config/Config.qml`** — Pure "keep both sides." Upstream added a `general.json` module
(terminal settings); our fork added a `calendar.json` module. Both `FileView` blocks,
both `*Ready` flags (folded into `initialLoadComplete`), both adapter property blocks,
both save functions, and both defaults imports were kept side by side. Verified
`resources`, `language`, and `excludedAudioSinks` config (our other features) auto-merged
cleanly outside the conflict markers and are intact.

**`config/defaults/system.js`** — Same additive principle, plus one real upstream content
change buried inside the same hunk (git's conflict region widened because our fork had
reformatted the file to tabs while upstream kept 4-space indentation): upstream renamed
the idle-timeout brightness commands from `ambxst brightness ...` to
`axctl brightness save/set/restore`. Took upstream's renamed commands, kept our
`language`, `resources`, and `ocr.rus` additions, and reformatted the whole file back to
4-space indentation to match every other file in `config/defaults/` (system.js was the
only tabbed file in that directory — a stray from our fork, not an upstream signal).
Validated the resulting `data` object as JSON after the edit.

**`modules/bar/BatteryIndicator.qml`** — One conflict: our tooltip
(`I18n.t("battery.status", ...)` / `I18n.t("battery.power_profile", ...)`) vs upstream's
reworded literal (added a " (Charging)" suffix, and renamed `PowerProfile` →
`PowerProfileClient` to match the rest of the file, which had already auto-merged to the
new name). Re-wrapped upstream's current wording: kept `battery.status` and
`battery.power_profile` as before (both already match upstream's text) and added the
charging suffix via the existing `battery.charging` key (`" (" + I18n.t("battery.charging") + ")"`,
following the same wrap-and-concatenate pattern already used elsewhere in the codebase,
e.g. `GradientStopsEditor.qml`). Updated the profile-name call site to `PowerProfileClient`.

**`modules/services/PowerProfile.qml`** — Modify/delete. Diffed our fork's only change to
this file against the merge-base and found it was exactly three `I18n.t()` wraps inside
`getProfileDisplayName()` (power-saver/balanced/performance), using keys
`power_profile.power_save` / `power_profile.balanced` / `power_profile.performance`.
Upstream's replacement `PowerProfileClient.qml` has an equivalent `getProfileDisplayName()`
with the identical literal wording ("Power Save" / "Balanced" / "Performance"). Accepted
upstream's deletion of the old file and re-applied the same three `I18n.t()` wraps onto
the equivalent function in `PowerProfileClient.qml` (same directory, so no new import
needed — consistent with how the old file called `I18n.t()` without importing it).

**`modules/services/SystemResources.qml`** — Structural, not textual: upstream replaced
the old `monitorProcess` (Python script `system_monitor.py`, now deleted from the repo)
with a `BackendService` subscription (`subscriptionHandle`, `activateMonitor`/
`deactivateMonitor`/`updateConfigure`/`handleEvent`, driven by a `monitoringActive`
computed property gated only on the dashboard Metrics tab being open). Our fork's only
change here (verified against merge-base) was extending that gating condition so bar
placement (`Config.system.resources.location === "bar" || "both"`) keeps monitoring alive
even when the dashboard is closed. Took upstream's architecture wholesale and re-applied
just that gating logic onto the new `monitoringActive` property:
```qml
readonly property bool monitoringActive: (Config.system.resources && Config.system.resources.enabled !== false)
    && ((GlobalStates.dashboardOpen && GlobalStates.dashboardCurrentTab === 2)
        || Config.system.resources.location === "bar" || Config.system.resources.location === "both")
    && root.validDisks.length > 0
```
No dead references to the removed `Process`/`SplitParser`/`monitorProcess` remain.

**`modules/services/WeatherService.qml`** — Same structural pattern: upstream replaced the
`weatherProcess` (curl-based `Process` + `StdioCollector`) with a `handleResponse(data)`
function fed by `BackendService.call("weather.get", ...)`. Adopted upstream's function
signature and null-check wholesale (the large parsing body after it had already auto-merged
as upstream's version, since our side never touched it beyond the process wrapper). Inside
that already-merged body, upstream's forecast-day-name line had also changed — from our
I18n-driven per-weekday keys to `dayDate.toLocaleDateString(Qt.locale(), "ddd")` (OS-locale
driven, three-letter form). Did **not** adopt that specific line: it isn't a wording change
to re-source-of-truth from (there's no static upstream string, it's a live locale call),
and swapping to it would silently defeat our i18n feature by tying this one label to system
locale instead of the user's chosen app language — while every other consumer of day names
in the app (`Clock.qml`, `Weather.qml`, `Calendar.qml`) still uses our
`calendar.day.{sun,mon,...}` two-letter keys via `I18n.t()`. Re-applied our original
`I18n.t("weather.today")` / `I18n.t(dayKeys[dayDate.getDay()])` logic in that spot instead,
keeping it consistent with the rest of the UI. `String()` coercion upstream added around
`daily.sunrise[0]`/`daily.sunset[0]`/`daily.time[i]` was kept (harmless robustness change,
already merged outside the conflict markers).

**`modules/widgets/dashboard/widgets/QuickControls.qml`** — Three conflicts, same shape as
`PowerProfile.qml`: upstream renamed `NightLightService`/`CaffeineService`/`GameModeService`
to `NightLightClient`/`CaffeineClient`/`GameModeClient` (new files under
`modules/services/`, backed by the Go daemon), and reworded the tooltips as plain literals
("Night Light: On" / "Caffeine: On" / "Game Mode: On", etc.). Re-wrapped with our existing
keys (`controls.night_light_on/off`, `controls.caffeine_on/off`, `controls.game_mode_on/off`
— all already matched upstream's wording exactly, no en.json changes needed) against the
renamed `*Client` singletons, including `CaffeineClient.toggle()` (upstream also renamed
the method from `toggleInhibit()`).

**`modules/widgets/tools/ToolsMenu.qml`** — Four conflicts in the `onActionTriggered`
handler. This file's `actions:` array (unconflicted, already merged) defines every tooltip
via `I18n.t("tools.xxx")`, so the click handler's `action.tooltip === ...` comparisons
*must* use the same `I18n.t()` calls to keep matching — using upstream's literal English
strings verbatim here would have silently broken the tool actions under any non-English
UI language (and been fragile even in English). For each conflict, took upstream's
structural rewrite and re-wrapped the tooltip comparison with the matching key:
- "Open Screenshots" / "Open Recordings": adopted upstream's `Screenshot.initialize()` /
  `ScreenRecorder.initialize()` + `.screenshotsDir`/`.videosDir` (config-aware, falls back
  to `$HOME/Pictures|Videos/...`) in place of our old `xdg-user-dir` shell-out. Re-wrapped
  with `I18n.t("tools.screenshot_directory")` / `I18n.t("tools.screenrecord_directory")`
  (both already matched upstream's wording).
- "Color Picker": dropped our unused legacy `scriptPath` var (dead code left over from a
  pre-Go-backend Python colorpicker script; nothing referenced it — the command already
  called `ambxst colorpicker`). Re-wrapped with `I18n.t("tools.color_picker")`.
- OCR/QR: upstream replaced the old per-language Tesseract shell scripts
  (`scripts/ocr.sh`, `scripts/qr_scan.sh`, driven by `Config.system.ocr` language toggles —
  pre-existing base functionality, not one of our six features, confirmed absent from our
  fork's diff against merge-base) with `Screenshot.captureMode = "ocr"/"qr"` routed through
  the same screenshot-capture pipeline already used by `google_lens`/`mirror` two lines
  below (confirming this is the current, adopted mechanism). Adopted that wholesale and
  re-wrapped with `I18n.t("tools.ocr")` / `I18n.t("tools.qr")` (both already matched).

Note for later tasks: `Config.system.ocr` (the eng/spa/lat/jpn/chi_sim/chi_tra/kor/rus
toggles in `Config.qml`/`system.js`) is now unreferenced by `ToolsMenu.qml` since OCR no
longer shells out to a language-configurable script. Left the config and its settings-UI
alone since it isn't one of the eight conflict files and cleaning it up is not conflict
resolution — flagging in case a later task wants to prune it.

## Translation keys whose English value changed

None. Every existing key touched by these conflicts already held a value matching
upstream's current wording (`battery.status`, `battery.power_profile`, `battery.charging`,
`power_profile.power_save/balanced/performance`, `controls.night_light_on/off`,
`controls.caffeine_on/off`, `controls.game_mode_on/off`, `tools.screenshot_directory`,
`tools.screenrecord_directory`, `tools.color_picker`, `tools.ocr`, `tools.qr` — all
verified against `translations/en.json` before resolving). `translations/en.json` has zero
staged changes in this commit. This list is empty as required by the brief, but I
deliberately did not touch `calendar.day.*` even though upstream's replacement code for
the weather forecast briefly produced different-length day abbreviations — see the
WeatherService.qml note above for why that wasn't a genuine wording conflict to resolve
via en.json.

## qml-check output

```
PASS: only the expected offscreen backend failure
```

## Commit

```
33de0589f7725154930ab0219c12c686d9b1fb59  merge: upstream main into all-features
```

Message is exactly as specified in the brief, no body, no trailers. Signed successfully
(no passphrase prompt). Working tree clean after commit. Verified `modules/services/I18n.qml`
and `modules/bar/AudioDeviceSwitcher.qml` were not touched by me (zero diff from the merge
in both). Verified the wheel `MouseArea` in `FullPlayer.qml` (line ~672) and
`modules/widgets/defaultview/CompactPlayer.qml` (line ~127) survived untouched.
