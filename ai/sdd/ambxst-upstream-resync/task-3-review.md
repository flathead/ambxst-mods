# Task 3 review — merge upstream main into `local/all-features-v2`

Reviewed commit `33de0589` (parents `c78f2a11` = ours, `6937e5b7` = upstream),
merge-base `4fa2f8c0`. Working tree clean, branch `local/all-features-v2`.

## Verdicts

- **Spec compliance: ✅**
- **Task quality: approved with issues** — 0 Critical, 2 Important, 3 Minor.
  No issue requires a change inside Task 3; both Important issues concern the
  report's accuracy and the hand-off to later tasks.

---

## How the diff was read

`git show --cc` shows a hunk whenever the merged result differs from both
parents *anywhere in that hunk*, which includes hunks where git simply
interleaved two non-overlapping auto-merged edits. The package's combined diff
therefore lists 13 files, but only lines carrying a **double** marker (`++`/`--`)
are actual human decisions. Extracting those:

```
config/Config.qml
config/defaults/system.js
modules/bar/BatteryIndicator.qml
modules/services/PowerProfileClient.qml
modules/services/SystemResources.qml
modules/services/WeatherService.qml
modules/widgets/dashboard/widgets/QuickControls.qml
```

`modules/widgets/tools/ToolsMenu.qml` carries no double-marked line at all: its
resolution picked our `I18n.t()` wrapper lines and upstream's body lines
verbatim, line by line, which is exactly the shape the brief asked for. The
other five files in the combined diff (`LayoutSelectorButton.qml`,
`ScreenshotTool.qml`, `Dashboard.qml`, `SystemPanel.qml`,
`calendar/Calendar.qml`) contain only single-marked lines — auto-merge
artifacts, not edits. **No file outside the sanctioned eight was hand-edited.**

## Both failure modes checked

**Direction 1 — upstream change silently dropped.** For all 19 files that both
our fork and upstream modified, I extracted every line upstream added relative
to the merge-base and checked its presence in the merged tree. Five lines are
absent, and every one is a documented, correct decision:

| Line absent from merge | Why that is correct |
|---|---|
| `Config.qml` `initialLoadComplete: … && generalReady` | folded into the combined `… && calendarReady && generalReady` (Config.qml:64) |
| `BatteryIndicator.qml` literal tooltip | re-wrapped with `I18n.t()` on upstream's current wording |
| `SystemResources.qml` `monitoringActive` + its comment | upstream's expression extended with our bar-placement gate |
| `WeatherService.qml` `Qt.locale()` day-name lines | deliberate, see below |
| `QuickControls.qml` three literal tooltips | re-wrapped with `I18n.t()` |

Nothing upstream deleted was resurrected (`git diff 6937e5b7 33de0589
--diff-filter=D` is empty), and `modules/services/PowerProfile.qml` is gone with
no dangling references (the only remaining `PowerProfile` token in the tree is a
comment at `BatteryIndicator.qml:154`). The Go-daemon migration is adopted
wholesale in both rewritten services: `SystemResources.qml` keeps upstream's
`subscriptionHandle` / `activateMonitor` / `updateConfigure` / `handleEvent`
structure with no `Process`, `SplitParser` or `monitorProcess` remnants, and
`WeatherService.qml` keeps upstream's `handleResponse(data)` and its `String()`
coercions with no `StdioCollector` remnants.

**Direction 2 — one of our features silently dropped.** Mirror check: every line
our fork added relative to the merge-base, checked for presence in the merged
tree. The only absences are the five intentional replacements above plus
`ToolsMenu.qml`'s `if (ocrConfig.rus === true) langs.push("rus");` (see Issue 2).
Relative to upstream, the merge adds exactly our 17 feature files and nothing
else. All six features are present and wired:

- keyboard layout: `KeyboardLayoutService.qml` + `KeyboardLayoutIndicator.qml`, referenced from `BarContent.qml`
- audio device switcher: `AudioDeviceSwitcher.qml` in `BarContent.qml`; `Config.qml:553 excludedAudioSinks` intact
- volume scroll: `Audio.incrementVolume()` still defined (`Audio.qml:171`, `:179`) and called from all three players
- bar resource monitor: `BarResourceMonitor.qml` in `BarContent.qml`; `Config.qml:1059 resources` intact
- i18n: 68 call sites, `en/ru/es` all 751 keys, exact key parity, `Config.qml:1058 language` intact
- calendar: `CalendarService.qml` + 6 UI files + `Config.qml:3587 calendar`, `scripts/calendar_service.py` present

No QML references a script upstream deleted; the four remaining `scripts/`
references all resolve.

## Global constraints

- Commit message is `merge: upstream main into all-features`, no body, no
  trailers, no generator footer. `%(trailers)` is empty.
- No AI artifacts anywhere in the tree; no `Co-Authored-By: Claude` or
  `Generated with [Claude Code]` in any tracked file. `PLAN.md` and
  `docs/MEMORY_AUDIT.md` both exist in the upstream parent — not ours.
- All added comments are English.
- `I18n.qml`, `AudioDeviceSwitcher.qml`, `KeyboardLayoutService.qml` and
  `CompactPlayer.qml` have a **zero** diff from our pre-merge branch.
  `FullPlayer.qml`'s only change is upstream's `width: parent.width - 32`; the
  wheel `MouseArea`s survive at `FullPlayer.qml:675` and `CompactPlayer.qml:130`,
  untouched, as Task 7 expects.
- `qml-check.sh` re-run independently: `PASS: only the expected offscreen backend
  failure`.

## The four specific claims

**1. PowerProfile → PowerProfileClient — verified, exactly as reported.**
Our fork's entire delta on the deleted `PowerProfile.qml` was three `I18n.t()`
wraps in `getProfileDisplayName()` (confirmed by diffing merge-base against
`c78f2a11`). `PowerProfileClient.qml:48-53` now carries those same three wraps on
the same three strings, and keeps upstream's `return name || "";` fallback rather
than the old file's `return profileName;`. Nothing else from the deleted file was
resurrected. `I18n` resolves without an import because both files sit in
`modules/services/` — the same pattern the deleted file and `WeatherService.qml`
already used.

**2. WeatherService day names — the reasoning holds and the result is
consistent.** `I18n.t()` resolves through `I18n.resolvedLanguage`, which comes
from `Config.system.language` and only falls back to the system locale when that
is `"auto"` (`I18n.qml:11`, `:42-50`). `Qt.locale()` is always the system locale.
The two therefore diverge exactly when a user has picked an explicit application
language — so adopting upstream's `dayDate.toLocaleDateString(Qt.locale(),
"ddd")` really would have produced English day names inside a Russian UI. The
result is also consistent: `Weather.qml:187-189` (the bar weather popup) already
builds the identical `calendar.day.*` key array, `Clock.qml:387` renders
`forecast.dayName`, and the calendar header uses the same keys
(`calendar/Calendar.qml:56-58`). See Minor issue 3 for the one loose end.

**3. Zero translation-key updates — verified.** Every key touched by the
resolution already held upstream's exact current wording:

```
battery.status              'Battery: %1%'        battery.charging   'Charging'
battery.power_profile       'Power Profile: %1'
power_profile.power_save    'Power Save'          .balanced 'Balanced'  .performance 'Performance'
controls.night_light_on/off 'Night Light: On/Off'
controls.caffeine_on/off    'Caffeine: On/Off'
controls.game_mode_on/off   'Game Mode: On/Off'
tools.screenshot_directory  'Open Screenshots'    tools.screenrecord_directory 'Open Recordings'
tools.color_picker          'Color Picker'        tools.ocr 'OCR'   tools.qr 'QR Code'
```

`translations/en.json` has zero staged changes in the merge commit, and `en`,
`ru`, `es` are all 751 keys with no missing or extra key on either side. The
claim is accurate.

**4. `Config.system.ocr` is NOT dead.** See Issue 1.

---

## Issues

### Issue 1 — Important — report claims `Config.system.ocr` is unreferenced; it is live

**Where:** `task-3-report.md:159-163` (the "Note for later tasks").
**Reality:** `modules/services/Screenshot.qml:259-275` defines `ocrLangs()`,
whose first statement is `var cfg = Config.system.ocr;` (line 260), and
`Screenshot.qml:233` calls it: `params.langs = root.ocrLangs();` on the
`ocr.text` backend path. That value becomes Tesseract's `-l` argument in
`backend/pkg/svc/ocr/service.go:50-55`. The settings UI at
`ShellPanel.qml:1886-1978` writes the same object.

**What it breaks in practice:** nothing today — the merged code is correct. The
danger is the hand-off. A later task acting on "flagging in case a later task
wants to prune it" would delete a config block that seven of eight OCR languages
still depend on, silently collapsing OCR to the backend's `"eng+spa"` default for
every user who selected Japanese, Korean, Chinese or Latin. The note should be
corrected to say the opposite: the config migrated from `ToolsMenu.qml` to
`Screenshot.qml` and must be kept.

### Issue 2 — Important — the `ocr.rus` toggle is now an orphan, and this was not reported

**Where:** `config/Config.qml:1050` (`property bool rus: false`),
`config/defaults/system.js:41` (`"rus": false`),
`ShellPanel.qml:1972-1978` (the checkbox labelled `shell.system.ocr_russian`,
"Russian").
**What is wrong:** our fork's Russian OCR language was consumed only by the
`ToolsMenu.qml` branch that the resolution correctly replaced with upstream's
`Screenshot.captureMode = "ocr"` pipeline. Upstream's replacement enumerator,
`Screenshot.ocrLangs()` (`Screenshot.qml:261-271`), pushes
`eng/spa/lat/jpn/chi_sim/chi_tra/kor` and has no `rus` branch.
**What it breaks in practice:** the "Russian" checkbox in Settings → OCR
Languages is now a silent no-op. A user who enables it and OCRs Cyrillic text
gets Latin-alphabet garbage, with no error and no indication why. Before the
merge it worked.

The *resolution* is right on both counts — keeping the config follows the brief's
"keep both sides", and adopting upstream's pipeline follows "take upstream's
structural changes". The one-line fix (`if (cfg.rus === true) langs.push("rus");`
in `Screenshot.qml`) belongs to a later task, since `Screenshot.qml` never
conflicted and Task 3 must not fix defects. But the regression needed to be
named in the report so a later task picks it up, and instead the report's only
OCR note points in the opposite direction (Issue 1).

### Issue 3 — Minor — forecast day abbreviations shrank from three letters to two

**Where:** `modules/services/WeatherService.qml:432-442`, rendered at
`Clock.qml:387`.
**What is wrong:** `calendar.day.*` holds two-letter values (`Su`, `Mo`, `Tu`…),
sized for a seven-column calendar header. Upstream's replacement produced
three-letter names (`"ddd"`) for the weather forecast row. Keeping our keys keeps
the pre-merge behaviour and is internally consistent (`Weather.qml:187-189` uses
the same keys), so nothing is broken — but the forecast row now reads `Mo Tu We`
where upstream intended `Mon Tue Wed`, and one key set is serving two different
width budgets.
**Suggestion for a later task:** a separate `weather.day.*` three-letter key set,
or accept the two-letter form deliberately. Out of scope here.

### Issue 4 — Minor — charging suffix is assembled by concatenation, not a key

**Where:** `modules/bar/BatteryIndicator.qml:189`.
**What is wrong:** `I18n.t("battery.status", pct) + " (" + I18n.t("battery.charging") + ")"`
hard-codes the parentheses and the word order outside the translation layer.
Translators cannot reorder or drop the parenthetical; `ru` renders
`Батарея: 50% (Зарядка)` and `es` `Batería: 50% (Cargando)`.
**Impact:** cosmetic. The pattern already exists elsewhere in the codebase, and
the cleaner alternative (a `battery.status_charging` key) would have required
en/ru/es edits that the brief's "zero key updates" outcome deliberately avoided.
Non-blocking; worth revisiting when Task 9 refreshes the languages.

### Issue 5 — Minor — whole-file reindentation of `config/defaults/system.js`

**Where:** `config/defaults/system.js`, all 67 lines.
**What is wrong:** the file was reformatted from tabs to 4 spaces, which goes a
little beyond strict conflict resolution and inflates that file's diff, making
the real change (upstream's `axctl brightness save/set/restore` rename, plus our
`language`/`resources`/`ocr.rus` blocks) harder to isolate.
**Verified harmless and justified:** the file still parses as JSON with keys
`disks, updateServiceEnabled, idle, ocr, pomodoro, language, resources`; the
tab-only-file claim checks out (all 16 files in `config/defaults/` now contain
zero tab-indented lines); and the tabs were what widened git's conflict region in
the first place, so normalising them is defensible. Non-blocking.

---

## What I could not verify from the diff or a static tree

- **Runtime behaviour of the new subscription gating.** `qml-check.sh` proves the
  tree loads; it does not prove that `BackendService`'s `systemmonitor`
  subscription actually keeps delivering while the dashboard is closed and
  `Config.system.resources.location === "bar"`. To confirm I would need a running
  shell with the Go daemon up, the bar monitor enabled and the dashboard closed,
  and a check that the bar widget's values keep advancing.
- **Whether Russian OCR would work if `rus` were re-added.** That depends on
  `tesseract-data-rus` being installed on the host; I only verified that the
  QML→daemon path drops the language, not that the daemon could honour it.
- **Whether the ru/es charging parenthetical reads naturally in context** — a
  native-reader judgement, not something the diff can settle.
