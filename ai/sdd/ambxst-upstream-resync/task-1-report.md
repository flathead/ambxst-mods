# Task 1 report: Safety net

Status: DONE_WITH_CONCERNS (one deviation from the brief's literal command, documented below; all outcomes match expectations)

## Pre-flight check (before any changes)

```
$ git branch --show-current
local/all-features
$ git log -1 --format=%H
c78f2a11aba881711b4e72de48faaacae142d8d0
$ git status --porcelain
 M modules/services/FocusGrabManager.qml
 M modules/services/GlobalShortcuts.qml
?? "assets/wallpapers_example/130263866_p0 1.png"
?? assets/wallpapers_example/130263866_p0.jpg
?? assets/wallpapers_example/background
?? assets/wallpapers_example/i.jpg
$ git worktree list
/home/flathead/.local/src/ambxst c78f2a11 [local/all-features]
$ git tag -l 'backup/*'
(empty)
```

Confirmed the repo matched the state described in the task context before making any changes. Also confirmed neither `~/ambxst-backup-2026-08-31/` nor `~/ambxst-v2` existed yet.

## Step 1: Tag the current state

Ran (as specified):
```
cd ~/.local/src/ambxst
git tag backup/pre-update-2026-08-31 local/all-features
```

**Deviation:** this failed with `fatal: нет описания метки?` ("no tag message?"). Root cause: the user's global `~/.gitconfig` has `[tag] gpgSign = true`, which turns a bare `git tag <name> <ref>` into an attempt at an annotated, GPG-signed tag — that requires a message and would also prompt for a GPG passphrase, which would hang non-interactively. This is a pre-existing global git setting unrelated to this task; I did not modify it.

**Fix applied:** re-ran the same tag creation with the signing config overridden for that single invocation only (not persisted to any config file):
```
git -c tag.gpgSign=false tag backup/pre-update-2026-08-31 local/all-features
```
This produces the plain lightweight tag the brief intended.

Verification:
```
$ git tag -l 'backup/*'
backup/pre-update-2026-08-31
$ git cat-file -t backup/pre-update-2026-08-31
commit
$ git rev-parse backup/pre-update-2026-08-31
c78f2a11aba881711b4e72de48faaacae142d8d0
```
Confirmed: lightweight tag, points directly at c78f2a11, matches `local/all-features` HEAD.

## Step 2: Back up the binary and config

Ran exactly as specified:
```
mkdir -p ~/ambxst-backup-2026-08-31
cp /usr/local/bin/ambxst ~/ambxst-backup-2026-08-31/ambxst-1.1.4
cp /usr/local/bin/axctl  ~/ambxst-backup-2026-08-31/axctl-old
cp -r ~/.local/share/ambxst/axctl.toml ~/.config/ambxst ~/ambxst-backup-2026-08-31/
```

Output of `ls -la ~/ambxst-backup-2026-08-31/`:
```
drwxr-xr-x    - flathead 31 авг 15:57 ambxst
.rwxr-xr-x  235 flathead 31 авг 15:57 ambxst-1.1.4
.rwxr-xr-x 6,0M flathead 31 авг 15:57 axctl-old
.rw-r--r--  13k flathead 31 авг 15:57 axctl.toml
```
(listing uses the user's `eza`-based `ls`; note `ambxst-1.1.4` is only 235 bytes — this matches the size of the currently installed `/usr/local/bin/ambxst`, so the copy is faithful to what's actually installed, it's just apparently a thin wrapper script rather than a large binary. Not something to fix in this task — flagging for awareness.)

All four expected entries present: `ambxst-1.1.4`, `axctl-old`, `axctl.toml`, `ambxst/`.

## Step 3: Stash the uncommitted overlay workaround

Per the coordinator's explicit ordering requirement: wrote the patch first, verified it non-empty and containing both filenames, only then discarded.

```
$ git diff modules/services/FocusGrabManager.qml modules/services/GlobalShortcuts.qml \
  > ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
exit=0
$ test -s ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch && echo PATCH_NON_EMPTY
PATCH_NON_EMPTY
$ grep -c "FocusGrabManager.qml" ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
3
$ grep -c "GlobalShortcuts.qml" ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
3
$ wc -l ~/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
72 /home/flathead/ambxst-backup-2026-08-31/clear-overlays-workaround.patch
```
Both filenames present (3 occurrences each — path appears in `diff --git`, `---`, `+++` headers), file is 72 lines / 2.5k, non-empty. Verification passed — proceeded to discard:

```
$ git checkout -- modules/services/FocusGrabManager.qml modules/services/GlobalShortcuts.qml
$ git status --porcelain
?? "assets/wallpapers_example/130263866_p0 1.png"
?? assets/wallpapers_example/130263866_p0.jpg
?? assets/wallpapers_example/background
?? assets/wallpapers_example/i.jpg
```
Only untracked wallpaper entries remain, as expected.

## Step 4: Create the worktree

Ran exactly as specified:
```
git branch local/all-features-v2 local/all-features
git worktree add ~/ambxst-v2 local/all-features-v2
cd ~/ambxst-v2 && git status -sb
```

Output:
```
Preparing worktree (checking out 'local/all-features-v2')
HEAD is now at c78f2a11 Merge branch 'main' into local/all-features
## local/all-features-v2
```
Matches expected `## local/all-features-v2`.

## Final verification (all commands from the coordinator's Verification section)

```
$ git tag -l 'backup/*'
backup/pre-update-2026-08-31

$ ls -la ~/ambxst-backup-2026-08-31/
drwxr-xr-x    - flathead 31 авг 15:57 ambxst
.rwxr-xr-x  235 flathead 31 авг 15:57 ambxst-1.1.4
.rwxr-xr-x 6,0M flathead 31 авг 15:57 axctl-old
.rw-r--r--  13k flathead 31 авг 15:57 axctl.toml
.rw-r--r-- 2,5k flathead 31 авг 15:57 clear-overlays-workaround.patch

$ git -C ~/ambxst-v2 status -sb
## local/all-features-v2

$ git -C /home/flathead/.local/src/ambxst status --porcelain
?? "assets/wallpapers_example/130263866_p0 1.png"
?? assets/wallpapers_example/130263866_p0.jpg
?? assets/wallpapers_example/background
?? assets/wallpapers_example/i.jpg

$ git -C /home/flathead/.local/src/ambxst log -1 --format=%H local/all-features
c78f2a11aba881711b4e72de48faaacae142d8d0
```

Additional cross-checks:
```
$ git -C /home/flathead/.local/src/ambxst worktree list
/home/flathead/.local/src/ambxst c78f2a11 [local/all-features]
/home/flathead/ambxst-v2         c78f2a11 [local/all-features-v2]

$ git -C /home/flathead/.local/src/ambxst branch -vv | grep local/all-features
* local/all-features                c78f2a11 Merge branch 'main' into local/all-features
+ local/all-features-v2             c78f2a11 (/home/flathead/ambxst-v2) Merge branch 'main' into local/all-features
```

Every verification point from the brief and the coordinator's instructions passes.

## What differed from the brief

- Step 1's exact command failed as written due to the user's pre-existing global `tag.gpgSign = true` git config, which is unrelated to this task and was not touched. Substituted an equivalent per-invocation override (`git -c tag.gpgSign=false tag ...`) to produce the same lightweight tag the brief describes. No git config file was modified.

## Concerns

- None regarding repo safety or data loss: `local/all-features` (the rollback branch) is untouched, still at `c78f2a11...`; the uncommitted overlay workaround is safely preserved as a patch and verified before discarding; the working tree now contains only the user's own untracked wallpaper files, exactly as before this task started.
- Minor observational note only: the backed-up `ambxst-1.1.4` binary is 235 bytes, suggesting the installed `/usr/local/bin/ambxst` is a thin wrapper/launcher rather than a compiled binary. This does not affect the backup's correctness (it copied exactly what's installed) but is worth knowing if a later task assumes it's a full binary.
- No AI artifacts, commits, or Hyprland config edits were made. This report lives outside the repository as instructed.
