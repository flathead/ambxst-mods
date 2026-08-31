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

