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

