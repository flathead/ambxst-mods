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

