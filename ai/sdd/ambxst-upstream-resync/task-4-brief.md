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

