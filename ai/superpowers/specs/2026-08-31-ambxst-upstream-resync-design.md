# Ambxst: upstream resync and fork hardening

**Date:** 2026-08-31
**Status:** approved, ready for planning
**Repository:** `~/.local/src/ambxst` (fork `flathead/Ambxst` over `Axenide/Ambxst`)

## Context

The fork is 110 commits behind upstream. Our last commit landed on 2 April; the
latest upstream commit is from 31 August. The installed `Ambxst 1.1.4` binary was
built on 13 May, while upstream has moved past 1.2.3.

Our work amounts to 46 commits across 92 files, +11779/−921. It lives in six
branches and is assembled into `local/all-features`, which the running shell uses
directly (`qs -p ~/.local/src/ambxst/shell.qml`). All six branches were submitted
upstream and all six pull requests are still open: #130 keyboard layout,
#131 audio device switcher, #132 volume scroll, #134 i18n, #136 resource monitor,
#142 calendar integration.

Several features misbehave. The user reports that the keyboard layout indicator
and the audio device switcher "sometimes don't work after boot" with no cause
identified, that i18n occasionally renders keys instead of strings, and that
volume scroll fails on the bar and island player.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Pull requests | Revive all six | Work is done and merge is still possible |
| Work order | Merge everything first, then fix, then split back into branches | User's call: faster feedback on the actual machine |
| Calendar | Keep as-is, refresh the PR | The user relies on it; the Python question belongs to the maintainer |
| i18n scope | Full EN and RU, machine-assisted ES | System locale is `ru_RU`; a half-translated UI is not acceptable |

## Root causes

Each cause below was traced in the source, not inferred from symptoms.

### 1. Keyboard layout: two silent dead ends with no retry

`modules/services/KeyboardLayoutService.qml`

`resolveSocket` builds the socket path from `HYPRLAND_INSTANCE_SIGNATURE` exactly
once. When quickshell starts before Hyprland exports that variable, the path comes
out malformed as `/run/user/1000/hypr//.socket2.sock`. The guard
`if (resolveSocket.socketPath)` lets it through because the string is not empty.
`ncat` then fails, and the reconnect timer retries the same cached bad path every
two seconds for the rest of the session.

The initial state fetch has the same shape. `hyprctl devices -j` runs only from
`onExited` of the xkb name parser. On a non-zero exit code `applyDevicesState` is
never called and nothing retries, so the indicator stays at `??` permanently.

Both failures persist for the whole session, which is why restarting the shell
fixes them and why the symptom looks random.

### 2. Audio device switcher: circular node binding

`modules/services/Audio.qml` filters devices on `node.audio`, and that field is
populated only for nodes bound through a `PwObjectTracker`. The tracker in
`Audio.qml` covers `[sink, source]` alone. Delegates in `AudioDeviceSwitcher.qml`
attach trackers to nodes taken from the list, but a node cannot enter the list
until it is bound. Empty list, nothing to track, empty list.

The switcher works only when something else has already bound the nodes, such as
the dashboard audio panel opened earlier in the session.

### 3. Volume scroll: shadowed by declaration order

In `modules/widgets/defaultview/CompactPlayer.qml` the wheel `MouseArea` is
declared before the content `StyledRect`, which puts it underneath, and child
items consume the wheel event. `FullPlayer.qml` has the same block appended at the
end, which is why it works there. Commit `72cb6ae0` fixed one file of the two.

### 4. i18n: async loading against synchronous bindings

`modules/services/I18n.qml` loads translations through an async `FileView`, while
`t()` returns the key itself when the map is empty. Anything rendered before the
JSON arrives, or assembled once into an array or model, keeps the key. Coverage
gaps compound the problem.

### Outside our changes

The broken idle timer is not our regression. Upstream carries `1ac1ddea fix
suspend lock race` and `46699af6 perf: defer lockscreen frame generation 5s after
boot`. Check whether the update fixes it before touching anything by hand.

## Verified assumptions

Checked before planning so the plan does not rest on recollection:

- Quickshell **0.3.0** (quickshell-git, AUR)
- `FileView.blockLoading` exists and applies only to an explicit `text()` or
  `data()` call, which decides the shape of the i18n fix
- `FileView.preload` exists, declared in the QML wrapper rather than in
  `.qmltypes`, so the current code is valid and holds no extra defect
- `Quickshell.env()` is already used in the project (`I18n.detectSystemLanguage`),
  so reading the Hyprland signature without a subprocess is acceptable
- `ncat`, `HYPRLAND_INSTANCE_SIGNATURE`, the `.socket2.sock` socket and
  `/usr/share/X11/xkb/rules/evdev.lst` are all present, which confirms the layout
  failure is a startup race rather than a missing dependency
- The project does not use `Quickshell.Hyprland`; its own event bus is
  `AxctlService.rawEvent`

## Phases

### Phase 0: safety net

The user's live desktop runs from the working checkout, so breaking that directory
breaks the desktop rather than a test run.

- tag `backup/pre-update-2026-08-31`; leave branch `local/all-features` unchanged
- copy the `/usr/local/bin/ambxst` binary (1.1.4), since a release cannot be rolled
  back from anywhere else
- copy `~/.local/share/ambxst/axctl.toml` and `~/.config/ambxst`
- do all work in a separate git worktree, leaving the running shell on the old
  checkout until the new tree is ready

Rollback path: restore the checkout, restore the binary, restart the shell.

### Phase 1: merge

Merge `origin/main` into `local/all-features-v2`. Expected conflict sites, heaviest
first: `config/Config.qml` (touched by all six features),
`config/defaults/system.js`, `SystemPanel.qml` and `Dashboard.qml`,
`FullPlayer.qml`, `Calendar.qml` and `Icons.qml`, and roughly 16 files carrying
i18n wrappers.

Verify separately that `scripts/calendar_service.py` survives commit `dc243132`,
where upstream dropped python and pipx from dependencies. `google-auth` was
installed through pipx.

Update the `ambxst` and `axctl` binaries through the upstream `install.sh`, which
pulls prebuilt artifacts from releases and needs sudo. Ask before running it.

**Exit criterion:** the shell starts, the bar renders, the dashboard opens. Not
polished, just not bricked.

### Phase 2: fixes

**Keyboard layout.** Read the signature through `Quickshell.env()` instead of a
subprocess. Check that the socket file exists rather than that the string is
non-empty. Make reconnect re-resolve the path instead of reusing the cached one.
Detach state initialization from xkb name parsing, since cosmetic data must not
gate startup, and give it bounded retries with backoff. Check whether
`AxctlService.rawEvent` carries layout events; if it does, drop `ncat` entirely,
which also matches where upstream is heading.

**Audio.** Add a `PwObjectTracker` covering all non-stream nodes inside
`AudioDeviceSwitcher.qml`. The fix stays self-contained and leaves the upstream
`Audio.qml` untouched, which matters for review.

**Volume scroll.** Move all three sites to `WheelHandler` instead of invisible
full-size `MouseArea` items. Declaration order stops mattering, so the "fixed one
file, forgot the other" regression cannot recur.

**i18n.** Switch the translation loaders to synchronous reads: `blockLoading: true`
together with an explicit `text()` call during singleton initialization. This is
the decisive part. In Quickshell 0.3.0 `blockLoading` affects only `text()` and
`data()` (see `/usr/lib/qt6/qml/Quickshell/Io/FileView.qml`), so waiting on the
`onLoaded` signal stays asynchronous regardless of the flag. The `strings` and
`fallback` maps have to be populated before the first binding evaluates.

Add a `revision` counter read inside `t()`, giving every binding an explicit
dependency that re-evaluates on language change and on late load. Make the final
fallback return the humanized last segment of the key (`Clear all`) instead of the
raw key (`notifications.clear_all`).

### Phase 3: i18n coverage

Add `scripts/i18n-check.sh`, written in shell rather than Python because upstream
is moving away from Python. It collects keys from `I18n.t(...)` calls, compares
them against `en.json`, and separately reports unwrapped literals in `text:`
properties. Run it and close the gaps across the new upstream UI (screenshots,
recording, OCR, QR, color picker, brightness): EN and RU in full, ES
machine-assisted and marked as such. The script stays in the repository so gaps
stop accumulating unnoticed.

### Phase 4: split back and refresh pull requests

Move each feature onto a fresh branch off `origin/main`, one at a time, carrying
only its own files. Verify that every branch works on its own, which is not
guaranteed today. Then force-push to the fork and update the six pull requests
describing the new base, the fixed defect, and the reasoning.

For #142, state the Python situation plainly in the comment so the maintainer can
decide deliberately instead of declining in silence.

## Verification

Every fix is verified by a scenario on the live shell rather than by reading code.

| Fix | Scenario |
|---|---|
| Keyboard layout | Restart the shell with `HYPRLAND_INSTANCE_SIGNATURE` deliberately blanked: the defect reproduces before the fix and disappears after |
| Audio | Cold start without opening the dashboard, device list populated |
| Volume scroll | Wheel over every player element in the bar and on the island |
| i18n | Start under `ru_RU`, then switch language at runtime |

## Out of scope

- rewriting the calendar in Go
- repairing the idle timer directly before checking whether the update fixes it
- refactoring upstream code beyond conflict resolution

The uncommitted `clear-overlays` workaround (`FocusGrabManager.clearAllGrabs()`
plus `GlobalShortcuts`) is set aside. Drop it if overlays stop sticking after the
update; otherwise finish it as separate work.
