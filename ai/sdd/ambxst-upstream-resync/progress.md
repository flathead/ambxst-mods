# SDD ledger — plan: /home/flathead/.local/src/ambxst-mods/ai/superpowers/plans/2026-08-31-ambxst-upstream-resync.md

Spec: /home/flathead/.local/src/ambxst-mods/ai/superpowers/specs/2026-08-31-ambxst-upstream-resync-design.md
Workspace deliberately outside the repository: the user requires that no AI
artifacts appear in the repo or in any commit.

## Pre-flight conflict scan

| Rows | Produces / Consumes | Finding |
|---|---|---|
| T1 → T2..T10 | worktree `~/ambxst-v2`, branch `local/all-features-v2` | see CONFLICT-1 |
| T2 → T3,5,6,7,8,9,10 | `qml-check.sh <tree>` gate | ok, tree path is a parameter |
| T3 → T7 | T3 drops the old FullPlayer wheel MouseArea, T7 adds WheelHandler | ok, deliberate handoff |
| T3 → T8,T9 | T3 re-wraps i18n during conflict resolution, T9 closes the rest | ok |
| T4 → T5..T9 | live checkout switched to the new branch | CONFLICT-1 |
| T1 → T4 | clear-overlays patch saved in T1, judged in T4 step 6 | ok |
| T8 → T9 | `t()`, `humanize()`, `revision` defined T8, exercised T9 | ok |
| T9 → T10 | T9 creates `scripts/i18n-check.sh` | GAP-1 |
| T5 internal | socketRediscover, initRetry, initAttempts defined and referenced | ok |
| T6 internal | single additive PwObjectTracker block | ok |
| T7 internal | file table lists ControlsButton as Modify, step 3 says change nothing | DOC-1 |
| T8 internal | loaders, loadAll, Component.onCompleted agree | ok |
| T9 internal | checker output feeds steps 3-4 | ok |
| T10 internal | per-branch verify worktree, push mapping *-v2 → * | ok |

CONFLICT-1: T4 step 4 runs `git checkout local/all-features-v2` in the main
checkout while T1 already has that branch checked out in the `~/ambxst-v2`
worktree. Git refuses the same branch in two worktrees, so T4 fails as written.

Ruling: T4 removes the worktree before switching the main checkout. Tasks 5-10
then operate in `~/.local/src/ambxst`. Isolation stops being useful at T4
anyway, because from there the goal is running it live. Cost if wrong: tasks
5-9 edit the tree the live shell uses, so a bad edit is visible until fixed;
mitigated because every task runs qml-check before reloading.

GAP-1: T10 derives each feature's file list from the original branches, which
predate `scripts/i18n-check.sh` and any other file created during T3-T9.

Ruling: T10 derives file lists from `origin/main..local/all-features-v2` and
assigns each new file to its feature by path, using the original branches only
as a cross-check. Cost if wrong: a new file lands on the wrong PR, caught by
the per-branch load check in T10 step 3.

DOC-1: T7's file table lists ControlsButton.qml as Modify while step 3 says to
leave it alone.

Ruling: ControlsButton is verify-only, no edit. Cost if wrong: none, cosmetic.

## Progress

Pre-flight recon (controller, read-only `git merge-tree`): the upstream merge
conflicts in exactly 8 files, not the wider set the spec predicted.
config/Config.qml, config/defaults/system.js, SystemResources.qml,
BatteryIndicator.qml, PowerProfile.qml, WeatherService.qml, QuickControls.qml,
ToolsMenu.qml. FullPlayer.qml, Dashboard.qml, SystemPanel.qml, Calendar.qml and
Icons.qml auto-merge.

Ruling: Task 3's resolution rules rewritten against the measured conflict set,
with an instruction to stop if git reports a file outside it. Cost if wrong: the
branches move before Task 3 runs and the list is stale, which the added stop
condition catches immediately.

Pre-flight recon (controller, read-only): Task 4 step 2's calendar dependency
question is already answered. `python3 -c "import google.auth, googleapiclient"`
succeeds and pipx is still installed at /usr/bin/pipx, so upstream dropping
python from its own dependency list did not break our calendar service. Task 4
still runs the check after the binary update, since the update is what could
change it.

Pre-flight recon (controller, read-only): the i18n coverage gap is far smaller
than the spec assumed. Counting `text: "literal"` across every QML file upstream
changed or added since our merge base gives 40 occurrences, concentrated in
SystemPanel.qml (26), TmuxTab.qml (7) and Pomodoro.qml (5). The regex is narrow
and Task 9's checker will find more, but the order of magnitude is tens, not
hundreds.

Task 1: complete (no commits — tag, backups and worktree only; verified by the
controller: tag backup/pre-update-2026-08-31 exists, local/all-features still at
c78f2a11, worktree ~/ambxst-v2 on local/all-features-v2, five backup entries
present, clear-overlays patch is 72 lines).

Ruling: Tasks 1 and 2 produce no repository commits, so a task reviewer would
receive an empty diff. Verified their outcomes directly instead of dispatching a
review. Cost if wrong: an infrastructure mistake reaches Task 3, where the merge
immediately exposes it.

Ruling: implementers commit normally with signing left enabled. The user has
commit.gpgsign and tag.gpgSign set to true with an openpgp key, and a probe
commit signed successfully without a passphrase prompt, so signing will not hang
a non-interactive subagent. Cost if wrong: a subagent stalls on a gpg prompt,
visible immediately as a timeout.
Note: existing commits on our feature branches are unsigned (%G? = N), so the
history will become mixed. Not worth rewriting.

Ruling: `ambxst update` in Task 4 is safe for our work. /usr/local/bin/ambxst is
a 5-line wrapper that execs the repo's cli.sh, and its update path runs the
upstream installer, which reads the current branch and skips the repository
sync when no refs/remotes/origin/<branch> exists. local/all-features-v2 is
local-only, so only axctl is replaced and our checkout is untouched. Cost if
wrong: the installer overwrites the checkout, recoverable from tag
backup/pre-update-2026-08-31.

Task 2: complete (no commits — qml-check.sh lives outside the repo; verified by
the controller: PASS on the known-good worktree, rc=0, and the worktree left
clean).

Ruling: Task 5 rewritten to delete the hand-rolled Hyprland IPC rather than
repair it. Quickshell 0.3.0 ships Quickshell.Hyprland, whose Hyprland singleton
owns the event socket, resolves its own path and reconnects by itself. Verified
live before rewriting: an offscreen probe printed the resolved eventSocketPath
and streamed rawEvent with .name and .data. This supersedes both the spec's
Quickshell.env() suggestion and this plan's earlier filesystem-discovery draft,
removes the ncat dependency entirely, and is far likelier to be accepted
upstream. Cost if wrong: a larger diff than a minimal patch, caught by
qml-check and the live layout-switch scenario in Task 5.

CORRECTION (controller, empirical): the spec's root cause for the audio device
switcher is WRONG and must not be implemented as written.

Claimed: node.audio is populated only for nodes bound through a PwObjectTracker,
so devices could never enter Audio.outputDevices (circular binding).

Measured, offscreen probes against the live PipeWire graph:
- with no tracker at all, 24 nodes appear, 8 are sink devices, and all 8 have
  .audio populated. The circular-binding theory is false.
- a bound property of the same shape as Audio.outputDevices re-evaluates
  correctly: the probe logged the count climbing 0,1,2,3 as nodes arrived.
  The reactivity theory is also false.
- what IS true: Pipewire.nodes.values is empty for roughly the first second
  after the shell starts and fills incrementally over about three seconds.

Task 6 is therefore blocked on a fact only the user has: what "the switcher
sometimes does not work" looks like in practice. Asked the user rather than
guessing, because every candidate fix targets a different failure.

Root cause found (controller, from user's symptom "list shows, switching does
not work"): the bar delegate calls Audio.setDefaultSink and then
devicePopup.close() in the same event-loop turn. setDefaultSink sets
Pipewire.preferredDefaultAudioSink, applied asynchronously by the session
manager, while close() destroys the delegate and its per-delegate
PwObjectTracker, the only thing binding the target node. The dashboard
equivalent (AudioDeviceItem.qml) calls the same function and closes nothing,
which is why that path never failed. Task 6 rewritten against this cause: root
level tracker plus a deferred close. Cost if wrong: the live five-times
switching scenario in Task 6 step 4 exposes it immediately.

Verified empirically (controller, offscreen probe) before Task 8 is dispatched:
at Component.onCompleted, which is when the first bindings evaluate, the current
async FileView with preload:true yields 0 translation keys while a FileView with
blockLoading:true read through an explicit text() call yields 751. The onLoaded
signal fires afterwards. Both the i18n root cause and the planned fix are
confirmed rather than assumed.

Verified (controller, git archaeology) before Task 7: commit 72cb6ae0 is the
origin of the volume-scroll defect. Its message states the MouseArea was moved
"to root Item level before StyledRect ... matching the correct z-order", but in
QML later siblings stack above earlier ones, so before the content means beneath
it. The same commit left the FullPlayer overlay last, where it works. Task 7
gained this evidence and a fallback to the proven MouseArea-placed-last form if
WheelHandler does not receive the events.

Task 3: merged (commit 33de0589, BASE c78f2a11, parent2 upstream 6937e5b7).
Conflict set matched the predicted eight. PowerProfile.qml turned out to be a
modify/delete conflict: upstream deleted it in favour of PowerProfileClient.qml,
and the implementer re-applied our three I18n.t wraps onto the new file. Zero
translation values needed updating. qml-check PASSED. Controller verified
independently that CompactPlayer.qml, I18n.qml, AudioDeviceSwitcher.qml and
KeyboardLayoutService.qml are untouched and all wheel handlers survive.
Review dispatched on opus over the combined diff (957 lines, 19 files).
Implementer concerns carried into review: WeatherService day-name decision,
architectural replacements in SystemResources/WeatherService/ToolsMenu, and
Config.system.ocr now unreferenced.

Measured on the merged tree (controller) before Task 9: en.json 751 keys, ru and
es at full parity (0 missing each), 592 keys referenced and all resolving, 163
defined-but-unused. The new upstream tools are already wrapped (ScreenshotTool
and ToolsMenu have zero raw literals), so the spec's premise for Task 9 is
obsolete. The real gap is ~41 unwrapped user-visible literals, 8 of them in our
own feature files that ship in the PRs. Task 9 brief updated with these numbers.

Task 3: complete (commits c78f2a11..33de0589, review spec OK, quality approved
with 2 Important and 3 Minor).

Ruling on Important 1 (report claims Config.system.ocr is unreferenced): the
reviewer is right and the implementer's note was wrong. Verified: Screenshot.qml
:233 calls ocrLangs(), which reads Config.system.ocr at :260. No code change is
needed because nobody acted on the note; the record is corrected here so no
later task prunes live config. Cost if wrong: none, this is a documentation fix.

Ruling on Important 2 (ocr.rus is an orphan): confirmed real. ocrLangs() handles
eng, spa, lat, jpn, chi_sim, chi_tra, kor and has no rus branch, while
Config.qml:1050, system.js:41 and a ShellPanel checkbox labelled ocr_russian all
still exist. The settings UI therefore shows a Russian OCR toggle that does
nothing, which matters to this user specifically. Out of Task 3's scope, so
scheduled into a batched cleanup task rather than reopening the merge. Cost if
wrong: Russian OCR stays broken, which is the status quo.

Ruling on Minor 3 (system.js reindent): DISMISSED as a false positive. Upstream
itself uses spaces (44 space-indented lines, 0 tabs) while our pre-merge branch
used tabs (63). The merge moved us toward upstream's style, and the diff against
upstream is 23 lines with or without -w, so there is no whitespace inflation.
Cost if wrong: none, measured.

Minor (deferred): weather forecast day names now render two letters because the
calendar-header keys are reused; upstream produced three. Scheduled into the
cleanup batch.
Minor (deferred): BatteryIndicator.qml:189 hardcodes the " (...)" charging
parentheses outside the translation layer. Scheduled into the cleanup batch.

BLOCKER FOUND (controller): the merged QML requires a Go daemon that is not
installed. modules/services/BackendService.qml bridges QML to "the ambxst Go
daemon over a Unix socket" at $XDG_RUNTIME_DIR/ambxst.sock, but the installed
/usr/local/bin/ambxst is the old 235-byte bash wrapper. Screenshots, recorder,
notifications, brightness and compositor dispatch all route through it. The
update is therefore mandatory, not optional, and it needs sudo, which requires a
password this session cannot supply. Handing the command to the user.

Task 4: complete. ambxst 1.2.5 and axctl v0.0.21 installed by the user (the
official updater could not be used: it pulls system packages through pacman and
the machine had 845 pending updates plus an ffmpeg soname conflict). Controller
downloaded both release binaries and verified ambxst against upstream's
published SHA256. Worktree removed, live checkout switched to
local/all-features-v2 (ac8f9e08), shell relaunched. Daemon socket present,
ambxst and axctl daemons running.

Incident during Task 4: the controller's own `pkill -f "qs -p ..."` matched its
own command line and killed the tool process mid-sequence. The shell had already
stopped cleanly via `ambxst quit`, so nothing was lost, but the relaunch was left
undone for one step. Use `pgrep -x` / `pkill -x` for process names from now on.

Blocker resolved (not ours): after the user's system upgrade, quickshell-git
(AUR, built 22 May) failed with an undefined Qt private symbol against the
qt6-base 6.11.2 installed at 17:11 today. Replaced with the repository package
quickshell 0.3.1, which is both newer than the AUR build and built against
current Qt. Our tree passes qml-check on it.

New finding carried into Task 6: the merged shell logs a Qt annotation error at
AudioDeviceSwitcher.qml:120 (findOutputById has no return type annotation; Qt
says the behaviour will change in a future version). Added to Task 6, which
already owns that file and ships it in PR #131.

