# Ambxst community mod packages

These packages contain the same source changes as the corresponding Ambxst pull
requests. They can be installed without replacing the base checkout, and their
patches remain suitable for normal upstream review.

## Install a package

The native manager must already be present. In **Settings → Mods**, paste either
a package repository URL or a GitHub package directory URL such as:

```text
https://github.com/flathead/ambxst-mods/tree/main/packages/keyboard-layout-indicator
```

The manager uses a shallow sparse checkout for a GitHub directory, so it does not
download the whole collection. A local clone works too:

```bash
ambxst mods install ./packages/keyboard-layout-indicator
ambxst mods enable community.keyboard-layout-indicator
ambxst reload
```

New packages are installed disabled. Review the manifest, permissions, and patch
before enabling one. Ambxst 1.3.0 and newer include runtime translations, so
these packages use the localization service provided by the base project. The
old `community.i18n` package must be removed before enabling current releases.

Use **Sort: Load order** to drag packages into the order in which their patches
should be composed. Dependencies always load before the packages that require
them. When two packages add something at the same place in a file, load order
decides which block comes first.

Calendar support needs `python3`, `notify-send`, and `xdg-open`. Google Calendar
accounts use `google-auth`, `google-auth-oauthlib`, and `google-api-python-client`;
CalDAV accounts use `caldav`, `icalendar`, and `requests`. Install the modules for
the provider you use into the Python environment that runs Ambxst. The manager
checks executables, not Python imports. Importing existing gcalcli credentials is
optional and requires a trusted local credential file.

Reminder sounds are optional. The calendar tries `canberra-gtk-play` for themed
sounds, then available `paplay`, `pw-play`, or `aplay` players. Custom sound files
can also use `ffplay`. These are alternatives, so the manifest does not require
all of them. Audio device switcher can read headset battery status through
`dbus-send` and ArctisManager; audio switching works without that service.
Keyboard layout names use `sh`, `awk`, and the system XKB rules at
`/usr/share/X11/xkb/rules/evdev.lst`.

## KDE Connect helper

KDE Connect helper is available at:

```text
https://github.com/flathead/ambxst-mods/tree/main/packages/kde-connect-helper
```

It adds a responsive bar button, a device popup, battery presentation, confirmed
file and text sharing, supported ping and ring actions, and official KDE Connect
launchers. The only mandatory command is `python3`; `kdeconnect-cli` remains
optional so the missing-package view can load. Text sharing also checks for the
Python D-Bus binding and stays disabled when it is unavailable. The manifest
declares D-Bus device access, executable discovery, explicit daemon and launcher
startup, confirmed device actions, optional package installation, user
autostart file management, and preferred-device storage.

On Arch and derivatives, the confirmed graphical installer uses `pkexec` with
pacman and the `kdeconnect` package. On Fedora and derivatives, it uses `pkexec`
with dnf and the `kde-connect` package. Installation never starts on load and
requires two deliberate steps. NixOS receives the declarative
`programs.kdeconnect.enable = true;` option and an optional user-profile command;
the mod never edits Nix, flake, Home Manager, Hyprland, Niri, shell profile, or
system configuration files.

Autostart prefers a marked user systemd service and falls back to a marked XDG
autostart entry. Disabling it removes only files owned by the mod. External
commands use validated executable paths and argument arrays without shell
evaluation. Privileged installation accepts only fixed, root-owned system
executables. Output is bounded, device identifiers are validated, operations
time out, and sharing requires confirmation.

## Languages and release metadata

Each package includes `CHANGELOG.md` and declares its interface language support.
Audio device switcher, Bar resource monitor, Keyboard layout indicator, and
Calendar integration use Ambxst's English, Russian, and Spanish dictionaries.
Calendar's Python service errors and notification actions remain in English;
event titles, device names, and provider responses keep their original language.
Volume scroll adds no interface text and declares `localization.mode: "none"`.
The resource monitor includes a patch for its missing empty-state translations.
KDE Connect helper translates its interface and settings into all three
languages.

Language metadata describes the implementation; it does not install translations.
These packages use base dictionaries, so they do not declare standalone resource
files. KDE Connect helper provides a native mod settings schema. The other
packages configure existing Ambxst settings directly. None depends on another
mod.

The packages are active and declare `deprecated: false`. A retired release should
set `deprecated: true` and explain removal in `deprecated_reason`. Do not mark a
working package deprecated just to demonstrate the notice.

Global automatic updates, per-mod overrides, and check frequency are controlled
in **Settings → Mods**, not in manifests. After applying an update, restart the
shell to load it. Volume scroll conflicts with the compact-player volume-scroll
example shipped in Ambxst; enable only one of them.

## Move a package into Ambxst core

Each package has one `patches/feature.patch`, generated against the tested
Ambxst revision recorded in its manifest. The manager merges patches three-way
when composing. Load order only matters when two packages add code at the same
location. Inspect the resulting source and run the project checks:

```bash
git switch -c feature/example origin/dev
git apply --check --whitespace=error-all packages/example/patches/feature.patch
git apply packages/example/patches/feature.patch
go test ./...
go vet ./...
```

Run the offscreen QML load check and the feature's manual scenario before opening
or updating a pull request. Once merged, the package can be retired; no adapter
layer or rewrite is required because a mod generation contains ordinary Ambxst
source files.
