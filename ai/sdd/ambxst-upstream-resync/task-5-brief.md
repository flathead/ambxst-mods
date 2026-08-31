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

