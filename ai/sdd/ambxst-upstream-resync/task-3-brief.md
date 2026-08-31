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

