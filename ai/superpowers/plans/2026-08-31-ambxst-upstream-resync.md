# Ambxst Upstream Resync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the fork up to current upstream, keep all six features working, fix the four reported defects at their root, and refresh the six open pull requests.

**Architecture:** Merge upstream into a scratch branch inside a git worktree so the running desktop stays on the old checkout. Fix defects on the merged tree, then split each feature back onto a clean branch cut from `origin/main`. Verification runs the shell offscreen, which resolves the whole QML type graph without drawing windows.

**Tech Stack:** QML (Quickshell 0.3.0), Hyprland, PipeWire, POSIX shell, Go binaries distributed as GitHub release artifacts.

**Spec:** `~/.local/src/ambxst-mods/ai/superpowers/specs/2026-08-31-ambxst-upstream-resync-design.md`

## Global Constraints

- Repository: `~/.local/src/ambxst`, live shell runs `qs -p ~/.local/src/ambxst/shell.qml`
- Branch `local/all-features` is the rollback point and must not be modified
- No AI artifacts in the repository or in any commit: no `docs/superpowers/`, no `.superpowers/`, no `Co-Authored-By` trailers, no generator footers. Plans and specs live in `~/.local/src/ambxst-mods/ai/`
- Commit messages, code comments and PR text in English, following the existing `type(scope): subject` convention
- Existing commits carry six `Co-Authored-By: Claude Sonnet 4.6` trailers that must be stripped during Task 10
- `qmllint` is broken on this system (exit 255, empty output, on every input). Do not use it
- Never edit Hyprland configs to work around Ambxst behaviour; Ambxst generates `~/.local/share/ambxst/hyprland.conf` from `axctl.toml`

## Verification harness

Every QML change is checked by loading the tree offscreen:

```bash
QT_QPA_PLATFORM=offscreen timeout 20s qs -p <tree>/shell.qml 2>&1 | tail -20
```

Offscreen has no layer-shell backend, so a healthy tree always ends with exactly this failure and nothing else:

```
ERROR: Failed to load configuration
ERROR:   caused by @shell.qml[33:5]: Type ContextMenu unavailable
ERROR:   caused by @modules/components/ContextMenu.qml[11:1]: No PanelWindow backend loaded.
```

Any other error, any different file, or any additional warning about a missing property or unresolved type means the change broke something. This resolves the full type graph, so it catches syntax errors, typos in property names and broken imports. It cannot catch runtime behaviour, which is why each fix also carries a live scenario.

## File structure

| File | Responsibility | Task |
|---|---|---|
| `~/.local/src/ambxst-mods/qml-check.sh` | Offscreen load check, kept out of the repository | 2 |
| `modules/services/KeyboardLayoutService.qml` | Socket discovery, retrying init, layout state | 5 |
| `modules/bar/AudioDeviceSwitcher.qml` | Bind all PipeWire device nodes, render switcher | 6 |
| `modules/widgets/defaultview/CompactPlayer.qml` | Wheel volume on the island player | 7 |
| `modules/widgets/dashboard/widgets/FullPlayer.qml` | Wheel volume on the dashboard player | 7 |
| `modules/bar/ControlsButton.qml` | Wheel volume on the bar control, verify only, no edit | 7 |
| `modules/services/I18n.qml` | Synchronous translation load, reactive lookup | 8 |
| `scripts/i18n-check.sh` | Key coverage gate, ships upstream in PR #134 | 9 |
| `translations/{en,ru,es}.json` | Translation data | 9 |

---

### Task 1: Safety net

**Files:**
- Create: `~/ambxst-backup-2026-08-31/` (outside the repository)

- [ ] **Step 1: Tag the current state**

```bash
cd ~/.local/src/ambxst
git tag backup/pre-update-2026-08-31 local/all-features
git tag -l 'backup/*'
```

Expected: `backup/pre-update-2026-08-31`

- [ ] **Step 2: Back up the binary and config**

The installed binary is 1.1.4 and upstream releases cannot be rolled back from anywhere else.

```bash
mkdir -p ~/ambxst-backup-2026-08-31
cp /usr/local/bin/ambxst ~/ambxst-backup-2026-08-31/ambxst-1.1.4
cp /usr/local/bin/axctl  ~/ambxst-backup-2026-08-31/axctl-old
cp -r ~/.local/share/ambxst/axctl.toml ~/.config/ambxst ~/ambxst-backup-2026-08-31/
ls -la ~/ambxst-backup-2026-08-31/
```

Expected: `ambxst-1.1.4`, `axctl-old`, `axctl.toml`, `ambxst/`

- [ ] **Step 3: Stash the uncommitted overlay workaround**

`FocusGrabManager.qml` and `GlobalShortcuts.qml` carry the uncommitted `clear-overlays` workaround. Preserve it as a patch outside the repo, then clean the tree.

```bash
git diff modules/services/FocusGrabManager.qml modules/services/GlobalShortcuts.qml \
  > ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
git checkout -- modules/services/FocusGrabManager.qml modules/services/GlobalShortcuts.qml
git status --porcelain
```

Expected: only untracked `assets/wallpapers_example/` entries remain

- [ ] **Step 4: Create the worktree**

The live desktop keeps running from the main checkout while work happens elsewhere.

```bash
git branch local/all-features-v2 local/all-features
git worktree add ~/ambxst-v2 local/all-features-v2
cd ~/ambxst-v2 && git status -sb
```

Expected: `## local/all-features-v2`

---

### Task 2: Offscreen load-check script

**Files:**
- Create: `~/.local/src/ambxst-mods/qml-check.sh`

This script is local tooling and stays out of the repository.

- [ ] **Step 1: Write the script**

```bash
cat > ~/.local/src/ambxst-mods/qml-check.sh <<'EOF'
#!/usr/bin/env bash
# Load an Ambxst tree offscreen and report anything beyond the expected
# layer-shell backend failure. Offscreen resolves the full QML type graph,
# so syntax errors and unknown properties surface here.
set -uo pipefail
TREE="${1:-$HOME/ambxst-v2}"
LOG=$(mktemp)
QT_QPA_PLATFORM=offscreen timeout 25s qs -p "$TREE/shell.qml" >"$LOG" 2>&1
# Strip ANSI colour, drop the known-good offscreen failure and its noise.
sed -e 's/\x1b\[[0-9;]*m//g' "$LOG" \
  | grep -E '^\s*(ERROR|WARN)' \
  | grep -vE 'No PanelWindow backend loaded|Type ContextMenu unavailable|Failed to load configuration' \
  | grep -vE 'WAYLAND_DISPLAY is present|set QT_QPA_PLATFORM|--- WARNING ---' \
  > "$LOG.filtered"
if [ -s "$LOG.filtered" ]; then
  echo "FAIL: unexpected diagnostics"
  cat "$LOG.filtered"
  rm -f "$LOG" "$LOG.filtered"
  exit 1
fi
echo "PASS: only the expected offscreen backend failure"
rm -f "$LOG" "$LOG.filtered"
EOF
chmod +x ~/.local/src/ambxst-mods/qml-check.sh
```

- [ ] **Step 2: Verify it passes on the known-good tree**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2
```

Expected: `PASS: only the expected offscreen backend failure`

- [ ] **Step 3: Verify it actually catches a break**

Prove the gate works before trusting it.

```bash
cd ~/ambxst-v2
cp modules/services/I18n.qml /tmp/I18n.qml.bak
printf '\nItem { property int broken: = }\n' >> modules/services/I18n.qml
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2; echo "rc=$?"
cp /tmp/I18n.qml.bak modules/services/I18n.qml
```

Expected: `FAIL: unexpected diagnostics` and `rc=1`, then the file is restored

---

### Task 3: Merge upstream

**Files:**
- Modify: conflict sites across the tree

**Interfaces:**
- Produces: branch `local/all-features-v2` containing upstream `origin/main` plus all six features

- [ ] **Step 1: Merge**

```bash
cd ~/ambxst-v2
git fetch origin
git merge origin/main
```

Expected: conflicts. Record the list before resolving.

```bash
git diff --name-only --diff-filter=U | tee /tmp/conflicts.txt
```

- [ ] **Step 2: Resolve the eight conflicting files**

`git merge-tree` was run against this exact pair of commits before the task was
dispatched, so the conflict set is known and closed. Exactly these eight files
conflict, and nothing else:

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

If `git merge` reports a file outside this list, stop and report it: the branches
moved since the prediction and the task needs re-scoping.

Resolution rules:

- `config/Config.qml` and `config/defaults/system.js`: keep both sides. Upstream
  added settings groups, our features added `resources`, `language`, `calendar`
  and `excludedAudioSinks`. All of it is additive and all of it must survive.
- `modules/services/SystemResources.qml`: this is our resource monitor against
  upstream edits to the same service. Take upstream's structural changes and
  re-apply our monitoring logic on top. Do not restore our version wholesale.
- `BatteryIndicator.qml`, `PowerProfile.qml`, `WeatherService.qml`,
  `QuickControls.qml`, `ToolsMenu.qml`: these conflict only where our `I18n.t(...)`
  wrappers meet upstream copy edits. Take upstream's text as the source of truth,
  then re-wrap it. Never keep our old English string just because it was already
  wrapped: upstream may have reworded it, and losing their edit to preserve our
  wrapper is the failure mode to avoid here. When upstream's wording differs from
  the string behind our existing key, update the value in `translations/en.json`
  to match and note the key in your report so Task 9 can refresh the other
  languages.

Files that do NOT conflict merge on their own, including
`modules/widgets/dashboard/widgets/FullPlayer.qml`. Our wheel `MouseArea` there
survives the merge untouched, and Task 7 replaces it with a `WheelHandler`. Leave
it alone in this task.

- [ ] **Step 3: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/ambxst-v2
```

Expected: `PASS`. If it fails, fix the reported file before committing.

- [ ] **Step 4: Commit the merge**

```bash
cd ~/ambxst-v2
git add -A
git commit -m "merge: upstream main into all-features"
```

---

### Task 4: Update the binaries

**Files:**
- Modify: `/usr/local/bin/ambxst`, `/usr/local/bin/axctl` (system paths, needs sudo)

- [ ] **Step 1: Ask the user before running anything with sudo**

This replaces system binaries on a live desktop. Confirm first, and confirm the shell may be restarted.

- [ ] **Step 2: Check the calendar dependency first**

Upstream commit `dc243132` dropped python and pipx from dependencies, and `google-auth` was installed through pipx. Confirm before the update whether the interpreter still resolves the imports.

```bash
python3 -c "import google.auth, googleapiclient; print('calendar deps OK')" 2>&1 | tail -3
```

Record the result. If it fails, the calendar feature is already broken independently of the update, and that finding goes to the user rather than being silently fixed.

- [ ] **Step 3: Update**

```bash
ambxst update
```

Expected: new binary fetched from releases. Verify:

```bash
ambxst --version
```

Expected: a version above 1.1.4

- [ ] **Step 4: Point the live shell at the new tree and restart**

Git refuses to check out the same branch in two worktrees, and Task 1 has
`local/all-features-v2` checked out in `~/ambxst-v2`. Retire the worktree first.
Isolation has done its job by this point: from here the goal is running the tree
live, and Tasks 5 through 10 work in the main checkout.

```bash
cd ~/ambxst-v2 && git status --porcelain   # must be empty before removing
cd ~/.local/src/ambxst
git worktree remove ~/ambxst-v2
git checkout local/all-features-v2
ambxst reload
```

Expected: the bar renders, the dashboard opens. Exit criterion is "not bricked", not "polished".

- [ ] **Step 5: Check the idle timer**

The user reported the built-in idle handling rotted. Upstream carries `1ac1ddea fix suspend lock race` and `46699af6 perf: defer lockscreen frame generation 5s after boot`. Verify whether the update fixed it and report the answer. Do not patch it in this plan.

- [ ] **Step 6: Decide the fate of the overlay workaround**

Task 1 saved the uncommitted `clear-overlays` workaround to
`~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch` and removed it from
the tree. Now check whether it is still needed.

Open and dismiss the dashboard, the settings window, the screenshot tool and the
lockscreen in turn, then confirm focus returns to the window underneath each
time and no invisible layer keeps swallowing clicks.

Expected if upstream fixed it: overlays release focus cleanly, and the patch is
discarded. If overlays still stick, report that to the user and treat the fix as
separate work rather than restoring the debug helpers, which exposed
`debugState()` over IPC and are not shippable as they stand.

---

### Task 5: Fix the keyboard layout startup race

**Files:**
- Modify: `modules/services/KeyboardLayoutService.qml`

**Root cause:** the socket path is resolved once from `HYPRLAND_INSTANCE_SIGNATURE`. When quickshell starts before Hyprland exports it, the path is malformed, the non-empty string passes the guard, and the reconnect timer retries the same bad path forever. Separately, the initial `hyprctl devices -j` runs only from the xkb parser's `onExited` and never retries on failure.

**Note superseding both the spec and the earlier draft of this task:** the spec
proposed reading the signature through `Quickshell.env()`, and an earlier draft
proposed discovering the socket on disk. Neither is needed. Quickshell ships
`Quickshell.Hyprland`, whose `Hyprland` singleton already owns the event socket
connection, resolves its path itself and reconnects on its own.

This was verified live on this machine before the task was written. A probe
loaded offscreen printed:

```
PROBE singleton ok, eventSocketPath = /run/user/1000/hypr/<sig>/.socket2.sock
PROBE rawEvent: activewindow | kitty,...
```

So the fix is to delete the hand-rolled IPC rather than repair it. That removes
the `ncat` dependency, the signature handling and the reconnect timer in one
move, and it is the version upstream is most likely to accept.

- [ ] **Step 1: Switch to the native Hyprland event source**

Add the import at the top of the file, beside the existing ones:

```qml
import Quickshell.Hyprland
```

Delete these three objects entirely, along with anything only they used:

- the `resolveSocket` Process
- the `socketListener` Process
- the `socketReconnect` Timer

Replace them with a single Connections block. `event.name` is the event type and
`event.data` is the payload after `>>`, so the old slicing of `"activelayout>>"`
is no longer needed:

```qml
    // Quickshell owns the Hyprland event socket: it resolves the path, connects
    // and reconnects. The previous implementation shelled out to ncat against a
    // path built once from HYPRLAND_INSTANCE_SIGNATURE, so when quickshell
    // started before Hyprland exported that variable the path was malformed and
    // the reconnect timer retried it forever.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;

            // data is "keyboard_name,layout_name"
            const commaIdx = event.data.lastIndexOf(",");
            if (commaIdx === -1)
                return;

            root.currentKeymap = event.data.substring(commaIdx + 1).trim();

            // Re-query devices for the authoritative active index.
            refreshProcess.buffer = "";
            refreshProcess.running = true;
        }
    }
```

- [ ] **Step 2: Confirm nothing still references the deleted objects**

```bash
cd ~/.local/src/ambxst
grep -nE "resolveSocket|socketListener|socketReconnect|ncat" modules/services/KeyboardLayoutService.qml
```

Expected: no output. If anything remains, remove it.

- [ ] **Step 3: Detach state initialization from xkb name parsing and give it retries**

This is the second, independent failure path: the initial `hyprctl devices -j`
runs only from `onExited` of the xkb name parser, and on a non-zero exit code
nothing retries, leaving the indicator at `??` for the whole session. The xkb
names are cosmetic and must not gate startup.

```qml
    property int initAttempts: 0

    Process {
        id: initProcess
        command: ["hyprctl", "devices", "-j"]
        running: true
        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: (data) => { initProcess.buffer += data; }
        }

        onExited: (code) => {
            if (code === 0 && initProcess.buffer !== "") {
                root.applyDevicesState(initProcess.buffer);
                root.initAttempts = 0;
            } else if (root.initAttempts < 15) {
                // Hyprland IPC is not up yet. Back off and retry rather than
                // leaving the indicator stuck for the rest of the session.
                root.initAttempts++;
                initRetry.restart();
            }
        }
    }

    Timer {
        id: initRetry
        interval: Math.min(1000 * root.initAttempts, 10000)
        onTriggered: {
            initProcess.buffer = "";
            initProcess.running = true;
        }
    }
```

In `xkbNamesProcess.onExited`, remove the line `initProcess.running = true;` so
the two chains are independent.

- [ ] **Step 4: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst
```

Expected: `PASS`

- [ ] **Step 5: Reproduce the original defect, then prove it is gone**

Start the shell with the signature deliberately blanked, which is the exact startup condition that broke it.

```bash
cd ~/.local/src/ambxst
env -u HYPRLAND_INSTANCE_SIGNATURE qs -p ~/.local/src/ambxst/shell.qml 2>&1 | grep -iE "layout|socket" | head
```

Expected after the fix: the service still finds the socket by discovery and the layout resolves. Before the fix, the same command leaves the indicator at `??`.

Then confirm live: `ambxst reload`, switch layout, confirm the bar indicator follows.

- [ ] **Step 6: Confirm the ncat dependency is gone**

The service was the only user of `ncat` in the codebase, so removing it drops an
external dependency the shell no longer needs.

```bash
cd ~/.local/src/ambxst
grep -rn "ncat" modules/ scripts/ install.sh
```

Expected: no output. Note the result in your report so the pull request can
mention the dropped dependency.

- [ ] **Step 7: Commit**

```bash
git add modules/services/KeyboardLayoutService.qml
git commit -m "fix(keyboard-layout): use Quickshell.Hyprland events instead of ncat

The socket path was built once from HYPRLAND_INSTANCE_SIGNATURE. When quickshell
started before Hyprland exported that variable the path came out malformed, the
non-empty guard let it through, and the reconnect timer retried the same dead
path for the rest of the session. The initial device query had the same shape:
chained off the xkb parser exit and never retried, so the indicator could sit at
'??' until the shell was restarted.

Quickshell.Hyprland already owns the event socket and reconnects on its own, so
delete the hand-rolled listener rather than repair it. This also drops the ncat
dependency, which the service was the only user of. Retry the device query with
backoff and stop gating it on the cosmetic xkb name lookup."
```

---

### Task 6: Fix the audio device switcher

**Files:**
- Modify: `modules/bar/AudioDeviceSwitcher.qml`

**Root cause, corrected and evidence-backed.** An earlier draft of this task
claimed devices never reached the list because unbound PipeWire nodes lack
`node.audio`. That was wrong, and probes against the live graph disproved it: with
no tracker at all, 24 nodes appear, 8 are sink devices, and all 8 have `.audio`
populated. A bound property of the same shape as `Audio.outputDevices` also
re-evaluates correctly as nodes arrive. Do not implement that fix.

The real defect is in switching, not listing. The user's symptom is that the list
shows correctly but selecting a device sometimes does nothing.

The bar switcher's delegate does this:

```qml
onClicked: {
    Audio.setDefaultSink(outputDelegate.modelData);
    devicePopup.close();
}
```

`Audio.setDefaultSink` sets `Pipewire.preferredDefaultAudioSink`, which is
applied asynchronously by the session manager. `devicePopup.close()` destroys the
Repeater delegate in the same event-loop turn, and with it the
`PwObjectTracker { objects: [outputDelegate.modelData] }` that was the only thing
binding that node. Whether the request survives the teardown is a race, which is
exactly why it works only sometimes.

The dashboard equivalent in `modules/widgets/dashboard/controls/AudioDeviceItem.qml`
calls the same function and does NOT close anything, which is why switching from
the dashboard has always been reliable. That contrast is the evidence.

- [ ] **Step 1: Keep device nodes bound independently of popup lifetime**

Add a tracker on the switcher root, so node bindings no longer depend on a
delegate that is about to be destroyed. Place it near the top of the root `Item`,
after the existing property declarations:

```qml
    // Device nodes must stay bound while a switch request is in flight. The
    // per-delegate trackers die with the popup, and the delegate is destroyed in
    // the same event-loop turn that requests the switch.
    PwObjectTracker {
        objects: Pipewire.nodes.values.filter(node => !node.isStream)
    }
```

- [ ] **Step 2: Stop destroying the delegate in the same turn as the request**

In both delegates, defer the close so the request is dispatched before teardown.
Output delegate:

```qml
                        onClicked: {
                            Audio.setDefaultSink(outputDelegate.modelData);
                            Qt.callLater(() => devicePopup.close());
                        }
```

Input delegate, the same shape:

```qml
                        onClicked: {
                            Audio.setDefaultSource(inputDelegate.modelData);
                            Qt.callLater(() => devicePopup.close());
                        }
```

Both changes are kept: the tracker removes the dependency on delegate lifetime,
the deferred close removes the same-turn teardown. Either alone narrows the race;
together they close it.

- [ ] **Step 3: Annotate the return type Qt is warning about**

Running the merged shell produces this at startup, from our own file:

```
ERROR: qs:@/qs/modules/bar/AudioDeviceSwitcher.qml:120: PwNodeIface should be
coerced to void because the function called is insufficiently annotated.
The original value is retained. This will change in a future version of Qt.
```

Line 120 is `const driver = root.findOutputById(driverId);`. The function has no
return type annotation, so Qt cannot type the call. Add one to
`findOutputById`, matching the style already used elsewhere in this file
(`function isExcluded(node): bool`):

```qml
    function findOutputById(id): var {
```

Check the file for other unannotated functions whose result is used, annotate
them the same way, and confirm the startup warning is gone in step 5. This ships
in PR #131, so leaving a warning Qt says will become an error is not acceptable.

- [ ] **Step 3: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst
```

Expected: `PASS`

- [ ] **Step 4: Verify switching actually switches**

```bash
ambxst reload
```

Play audio so the active device is audible. Then, WITHOUT opening the dashboard
first, open the bar audio switcher and select a different output. Expected: audio
moves to the selected device and the checkmark follows, every time.

Repeat at least five times, alternating between two devices, because the defect
is a race and a single success proves nothing. Then repeat for the input side
using `wpctl status` to confirm the default source changed:

```bash
wpctl status | sed -n '/Sinks:/,/Filters:/p'
```

Expected: the device marked with `*` matches what you selected.

- [ ] **Step 5: Commit**

```bash
git add modules/bar/AudioDeviceSwitcher.qml
git commit -m "fix(audio-switcher): keep nodes bound while a switch is in flight

Selecting a device from the bar switcher worked only sometimes. Setting
Pipewire.preferredDefaultAudioSink is applied asynchronously, but the click
handler closed the popup in the same event-loop turn, destroying the delegate
and the PwObjectTracker that was the only thing binding the target node. Whether
the request survived that teardown was a race.

The dashboard path calls the same function without closing anything, which is
why switching from there was always reliable.

Track device nodes on the switcher root so bindings no longer depend on the
popup, and defer the close so the request is dispatched first."
```

### Task 7: Fix volume scroll on the players

**Files:**
- Modify: `modules/widgets/defaultview/CompactPlayer.qml`
- Modify: `modules/widgets/dashboard/widgets/FullPlayer.qml`
- Modify: `modules/bar/ControlsButton.qml`

**Root cause:** in `CompactPlayer.qml` the wheel `MouseArea` is declared before the content `StyledRect`, so it sits underneath and child items consume the wheel. `FullPlayer.qml` has the same block appended last, which is why it works there. Commit `72cb6ae0` fixed one file of the two.

Switching to `WheelHandler` removes declaration order from the equation, so the same regression cannot come back through a later refactor.

**Evidence.** Commit `72cb6ae0` ("fix: correct MouseArea placement for volume
scroll on players") is itself the origin of the defect. Its message reads: "Move
CompactPlayer scroll MouseArea to root Item level before StyledRect instead of
inside BarPopup, matching the correct z-order for wheel event capture." Moving it
out of the popup was right, but "before" is backwards: in QML later siblings
stack above earlier ones, so placing it before the content put it underneath.
The same commit removed `z: 0` from the FullPlayer overlay, where the block sits
last and therefore works. That contrast is the natural experiment.

**If WheelHandler does not receive the events**, do not fight it: fall back to the
MouseArea form that is already proven to work in `FullPlayer.qml`, placed LAST
among its siblings with `acceptedButtons: Qt.NoButton`. Report which form you
used. Correct behaviour matters more than the more modern API here.

- [ ] **Step 1: Replace the MouseArea in CompactPlayer**

Delete the `MouseArea` block added before the content `StyledRect` and add a handler on the root item instead:

```qml
    // WheelHandler rather than a full-size MouseArea: a MouseArea competes on
    // declaration order and child items swallow the wheel event when it is
    // declared before the content.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (!compactPlayer.player)
                return;
            if (event.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (event.angleDelta.y < 0)
                Audio.decrementVolume();
        }
    }
```

- [ ] **Step 2: Replace the MouseArea in FullPlayer**

Delete the trailing `MouseArea` block and add:

```qml
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (event.angleDelta.y < 0)
                Audio.decrementVolume();
        }
    }
```

- [ ] **Step 3: Leave ControlsButton on its existing handler**

`ControlsButton.qml` adds `onWheel` to a `MouseArea` that already exists for clicks, which is correct and has no ordering problem. Change nothing there.

- [ ] **Step 4: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst
```

Expected: `PASS`

- [ ] **Step 5: Verify live over every player element**

```bash
ambxst reload
```

Start playback, then scroll the wheel over each of: the album art, the track title, the progress bar, the play and skip buttons, and the empty space around them. Do this on the island player and in the dashboard player. Expected: volume changes everywhere, and the OSD appears.

- [ ] **Step 6: Commit**

```bash
git add modules/widgets/defaultview/CompactPlayer.qml modules/widgets/dashboard/widgets/FullPlayer.qml
git commit -m "fix(volume-scroll): use WheelHandler so stacking order stops mattering

In CompactPlayer the wheel MouseArea was declared before the content, which put
it underneath, and child items consumed the wheel. FullPlayer had the same block
appended last and therefore worked, so the bug reproduced on the island player
only.

WheelHandler does not depend on declaration order, so a later refactor cannot
reintroduce the same asymmetry."
```

---

### Task 8: Fix the i18n loading race

**Files:**
- Modify: `modules/services/I18n.qml`

**Root cause:** translations load through an async `FileView` while `t()` returns the key itself when the map is empty. Anything rendered before the JSON arrives keeps the key. In Quickshell 0.3.0 `blockLoading` applies only to an explicit `text()` or `data()` call, so waiting on `onLoaded` stays asynchronous no matter what the flag says.

- [ ] **Step 1: Add the revision counter and a humanized fallback**

Replace the property block and `t()`:

```qml
    property var strings: ({})
    property var fallback: ({})
    property var availableLanguages: ({})
    property bool ready: false
    // Bumped after every successful load. t() reads it so that every binding
    // which calls t() takes a dependency and re-evaluates on language change.
    property int revision: 0

    // Last resort when a key is missing entirely: "notifications.clear_all"
    // renders as "Clear all" rather than leaking the key into the UI.
    function humanize(key) {
        const seg = key.substring(key.lastIndexOf(".") + 1).replace(/_/g, " ");
        return seg.charAt(0).toUpperCase() + seg.slice(1);
    }

    function t(key) {
        const rev = root.revision; // dependency capture, do not remove
        let str = root.strings[key] ?? root.fallback[key] ?? root.humanize(key);
        for (let i = 1; i < arguments.length; i++)
            str = str.replace("%" + i, arguments[i]);
        return str;
    }
```

- [ ] **Step 2: Make the loaders synchronous**

Replace all three `FileView` blocks and the `onResolvedLanguageChanged` handler:

```qml
    FileView {
        id: languagesLoader
        path: Qt.resolvedUrl("../../translations/languages.json")
        blockLoading: true
    }

    FileView {
        id: fallbackLoader
        path: Qt.resolvedUrl("../../translations/en.json")
        blockLoading: true
    }

    FileView {
        id: langLoader
        path: root.resolvedLanguage !== "en"
              ? Qt.resolvedUrl("../../translations/" + root.resolvedLanguage + ".json")
              : ""
        blockLoading: true
    }

    // blockLoading only takes effect on an explicit text() call, so read the
    // files here rather than waiting for onLoaded. The maps must be populated
    // before the first binding evaluates, otherwise raw keys reach the screen.
    function loadAll() {
        try {
            root.availableLanguages = JSON.parse(languagesLoader.text());
        } catch (e) {
            console.warn("I18n: failed to parse languages.json:", e);
            root.availableLanguages = { "en": "English" };
        }

        try {
            root.fallback = JSON.parse(fallbackLoader.text());
        } catch (e) {
            console.warn("I18n: failed to parse en.json:", e);
            root.fallback = ({});
        }

        root.resolvedLanguage = root.resolveLanguage();

        if (root.resolvedLanguage === "en") {
            root.strings = root.fallback;
        } else {
            try {
                root.strings = JSON.parse(langLoader.text());
            } catch (e) {
                console.warn("I18n: failed to parse " + root.resolvedLanguage + ".json:", e);
                root.strings = root.fallback;
            }
        }

        root.ready = Object.keys(root.fallback).length > 0;
        root.revision++;
    }

    Component.onCompleted: root.loadAll()

    onConfigLanguageChanged: root.loadAll()
```

Remove the old `onConfigLanguageChanged` and `onResolvedLanguageChanged` handlers that only assigned `resolvedLanguage`, since `loadAll()` now owns that.

- [ ] **Step 3: Verify the tree loads**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst
```

Expected: `PASS`

- [ ] **Step 4: Verify no raw keys at startup**

The system locale is `ru_RU.UTF-8`, so a cold start exercises the non-English path.

```bash
ambxst reload
```

Expected: the bar, dashboard and settings show Russian text immediately, with no dotted identifiers anywhere. Open the settings window and scan the sidebar and every panel heading.

- [ ] **Step 5: Verify runtime language switching**

In settings, switch language to English, then to Spanish, then back to Russian. Expected: every visible string updates without restarting the shell. Before the revision counter, strings assembled once kept the previous language.

- [ ] **Step 6: Commit**

```bash
git add modules/services/I18n.qml
git commit -m "fix(i18n): load translations synchronously and re-evaluate on change

Translations loaded through an async FileView while t() returned the key when
the map was empty, so anything rendered before the JSON arrived kept the key on
screen. In Quickshell 0.3.0 blockLoading applies only to an explicit text() or
data() call, so waiting on onLoaded stayed asynchronous regardless of the flag.

Read the files explicitly during initialization, bump a revision counter that
t() reads so bindings re-evaluate on language change, and humanize the last
segment when a key is missing instead of leaking the identifier."
```

---

### Task 9: Close i18n coverage across the new upstream UI

**Files:**
- Create: `scripts/i18n-check.sh`
- Modify: `translations/en.json`, `translations/ru.json`, `translations/es.json`
- Modify: QML files reported as carrying unwrapped strings

**Measured baseline, taken on the merged tree before this task was dispatched.**
The situation is not what the spec assumed, so do not re-derive it:

- `translations/en.json` holds 751 keys; `ru.json` and `es.json` are both at full
  parity with it, missing nothing. Language files do not need backfilling.
- 592 keys are referenced from QML. Every one resolves; the only apparent misses
  are dynamic prefixes such as `I18n.t("settings.shell." + name)`, which the
  checker must not report as missing.
- 163 keys are defined but unreferenced. Leave them: they are cheap, and deleting
  keys risks breaking dynamic lookups. Report the count, do not act on it.
- The new upstream tools are ALREADY wrapped. `ScreenshotTool.qml` and
  `ToolsMenu.qml` contain zero raw literals. The spec's assumption that they
  arrived hardcoded is obsolete: the merge in Task 3 wrapped them.

The real remaining gap is about 41 unwrapped user-visible literals across
`text:`, `label:`, `title:`, `placeholderText:`, `description:` and `summary:`.
Ignore `name:` — those 48 occurrences are internal identifiers, not UI copy.

Eight of those literals are in OUR OWN feature files and will ship in the pull
requests, which makes them the priority: `BarResourceMonitor.qml` (5),
`AudioDeviceSwitcher.qml` (2), `CalendarPanel.qml` (1).

- [ ] **Step 1: Write the coverage checker**

Shell rather than Python, because upstream dropped python from its dependencies in `dc243132`.

```bash
cat > scripts/i18n-check.sh <<'EOF'
#!/usr/bin/env bash
# Report translation keys used in QML but missing from en.json, and string
# literals in QML that are still unwrapped. Run from the repository root.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EN="$ROOT/translations/en.json"
status=0

# Keys referenced from QML.
grep -rhoE 'I18n\.t\("([^"]+)"' "$ROOT/modules" \
  | sed -E 's/I18n\.t\("//' | sort -u > /tmp/i18n-used.txt

# Keys defined in en.json.
grep -oE '^\s*"[^"]+"\s*:' "$EN" | sed -E 's/^\s*"//; s/"\s*:$//' | sort -u > /tmp/i18n-defined.txt

missing=$(comm -23 /tmp/i18n-used.txt /tmp/i18n-defined.txt)
if [ -n "$missing" ]; then
  echo "Keys used in QML but missing from en.json:"
  echo "$missing" | sed 's/^/  /'
  status=1
fi

unused=$(comm -13 /tmp/i18n-used.txt /tmp/i18n-defined.txt)
if [ -n "$unused" ]; then
  echo "Keys defined but never used:"
  echo "$unused" | sed 's/^/  /'
fi

# Unwrapped user-visible literals.
echo "Unwrapped text: literals:"
grep -rnE '^\s*text:\s*"[^"]+"' "$ROOT/modules" \
  | grep -vE 'I18n\.t|text:\s*""' | sed 's/^/  /' || true

exit $status
EOF
chmod +x scripts/i18n-check.sh
```

- [ ] **Step 2: Run it and capture the gap list**

```bash
cd ~/.local/src/ambxst && ./scripts/i18n-check.sh | tee /tmp/i18n-gaps.txt
```

Expected: a list of missing keys and unwrapped literals, dominated by the new upstream tools.

- [ ] **Step 3: Wrap the reported literals**

For every file in the unwrapped list, replace `text: "Some string"` with `text: I18n.t("scope.some_string")`, adding `import qs.modules.services` where the file lacks it. Follow the existing key naming: lowercase, dot-separated scope, snake_case leaf, scope named after the feature (`screenshot.`, `recorder.`, `ocr.`, `qr.`, `colorpicker.`, `brightness.`).

- [ ] **Step 4: Add the keys to all three translation files**

Add every new key to `en.json` and `ru.json` with real translations. Add them to `es.json` machine-assisted, and note in the PR description that Spanish is machine-assisted and welcomes review from a native speaker.

- [ ] **Step 5: Verify coverage is clean**

```bash
cd ~/.local/src/ambxst && ./scripts/i18n-check.sh; echo "rc=$?"
```

Expected: `rc=0`, no missing keys, and no unwrapped literals other than deliberate non-text values.

- [ ] **Step 6: Verify all three languages render**

```bash
~/.local/src/ambxst-mods/qml-check.sh ~/.local/src/ambxst && ambxst reload
```

Open the screenshot tool, the recorder, OCR, QR and the colour picker under each language. Expected: no dotted identifiers and no untranslated English while another language is selected.

- [ ] **Step 7: Commit**

```bash
git add scripts/i18n-check.sh translations modules
git commit -m "i18n: cover the new upstream tools and add a coverage checker

Screenshots, recording, OCR, QR, the colour picker and brightness arrived with
hardcoded strings. Wrap them, add the keys to English, Russian and Spanish, and
add scripts/i18n-check.sh so missing keys and unwrapped literals are reported
instead of accumulating unnoticed.

Spanish is machine-assisted and would benefit from review by a native speaker."
```

---

### Task 10: Split into clean branches and refresh the pull requests

**Files:**
- Create: six branches cut from `origin/main`

**Interfaces:**
- Consumes: the finished `local/all-features-v2` tree from Tasks 3 through 9
- Produces: `feature/{keyboard-layout-indicator,audio-device-switcher,volume-scroll,bar-resource-monitor,i18n,calendar-integration}` rebuilt on current upstream

- [ ] **Step 1: Confirm no AI artifacts can reach upstream**

```bash
cd ~/.local/src/ambxst
git log --format='%B' origin/main..HEAD | grep -icE "co-authored-by|claude|anthropic|generated with" 
git diff --name-only origin/main..HEAD | grep -iE "superpowers|CLAUDE\.md|ai-handoff"
```

Expected: `0` from the first command and no output from the second. If either fails, fix before pushing.

- [ ] **Step 2: Rebuild each feature branch, one at a time**

For each feature, cut a fresh branch from upstream and carry only that feature's files. Example for the keyboard layout, repeated per feature with its own file list:

```bash
cd ~/.local/src/ambxst
git checkout -b feature/keyboard-layout-indicator-v2 origin/main
git checkout local/all-features-v2 -- \
  modules/services/KeyboardLayoutService.qml \
  modules/bar/KeyboardLayoutIndicator.qml
# Config.qml and defaults carry settings for several features. Copy only the
# keyboard-layout entries by hand rather than taking the whole file.
git add -A
git commit -m "feat: add keyboard layout indicator to bar"
```

Derive each feature's file list from the finished branch rather than from the
original ones. Files created during Tasks 3 through 9, such as
`scripts/i18n-check.sh`, do not exist on the stale branches and would be dropped.

```bash
# Every file our work touches, against current upstream.
git diff --name-only origin/main..local/all-features-v2
```

Assign each path to its feature by ownership: `KeyboardLayout*` to the layout
branch, `AudioDeviceSwitcher.qml` to the audio branch, the player files to volume
scroll, `SystemResources.qml` and `BarResourceMonitor.qml` to the resource
monitor, `I18n.qml`, `translations/` and `scripts/i18n-check.sh` to i18n, and the
calendar files to calendar. Cross-check against the original branches, which
remain a useful reference for everything that predates this work:

```bash
for b in feature/keyboard-layout-indicator feature/audio-device-switcher \
         feature/volume-scroll feature/bar-resource-monitor \
         feature/i18n feature/calendar-integration; do
  echo "=== $b"; git diff --name-only $(git merge-base $b origin/main) $b
done
```

Files touched by several features, `config/Config.qml` and
`config/defaults/system.js` above all, are split by hand: each branch carries
only its own settings entries.

- [ ] **Step 3: Verify each branch loads on its own**

This is not guaranteed today, and a branch that only works alongside its siblings will fail review.

```bash
git worktree add /tmp/verify-branch feature/keyboard-layout-indicator-v2
~/.local/src/ambxst-mods/qml-check.sh /tmp/verify-branch
git worktree remove /tmp/verify-branch
```

Expected: `PASS` for every branch. Repeat per feature.

- [ ] **Step 4: Ask the user before pushing**

Force-pushing rewrites six public pull request branches. Confirm before touching the remote.

- [ ] **Step 5: Push and update the pull requests**

```bash
git push --force-with-lease fork feature/keyboard-layout-indicator-v2:feature/keyboard-layout-indicator
```

Then comment on each PR describing the new base, the defect fixed, and the reasoning. For #142, state the Python situation plainly: upstream dropped python and pipx in `dc243132`, the calendar service depends on `google-auth`, and the maintainer should decide deliberately rather than decline in silence.

- [ ] **Step 6: Restore the live checkout**

```bash
cd ~/.local/src/ambxst
git status -sb
```

Confirm the running shell is on the intended branch and that `~/.local/src/ambxst` is either kept for further work or removed with `git worktree remove`.

---

## Rollback

If anything in Tasks 3 or 4 leaves the desktop unusable:

```bash
cd ~/.local/src/ambxst
git checkout local/all-features
sudo install -m 755 ~/ambxst-backup-2026-08-31/ambxst-1.1.4 /usr/local/bin/ambxst
ambxst reload
```
