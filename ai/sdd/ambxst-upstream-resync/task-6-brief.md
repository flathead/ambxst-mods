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

