# KDE Connect helper

KDE Connect helper adds a 36-pixel Ambxst bar control for paired devices. It supports horizontal and vertical bars, connected and offline devices, multiple-device selection, battery status, and Ambxst styling.

The popup can refresh discovery, start the daemon, open an installed official KDE Connect interface, manage user autostart, ping or ring a supported device, and share a confirmed file or text. Unsupported actions stay disabled and explain why. Device state comes from structured D-Bus properties instead of localized CLI output.

## Install

Paste this URL into **Settings > Mods**:

```text
https://github.com/flathead/ambxst-mods/tree/main/packages/kde-connect-helper
```

For a local checkout:

```bash
ambxst mods install ./packages/kde-connect-helper
ambxst mods enable community.kde-connect-helper
ambxst reload
```

The only mandatory manifest command is `python3`. KDE Connect is intentionally optional so the helper can load and present installation guidance when it is missing. Text sharing uses the Python D-Bus binding when available, which keeps shared text out of process arguments. The action stays disabled with a clear reason when that binding is unavailable.

## Installation behavior

The helper detects the distribution, package manager, package name, and `pkexec` before offering an installation. It never installs on load. Arch and derivatives use the official `kdeconnect` package with pacman. Fedora and derivatives use the official `kde-connect` package with dnf. Both routes require a deliberate action followed by a separate confirmation.

NixOS remains declarative. The helper shows `programs.kdeconnect.enable = true;` and an optional `nix profile` command, but never edits NixOS, flake, or Home Manager files. Unknown distributions receive manual guidance instead of a guessed command.

## Autostart and security

Autostart uses a marked user systemd service when the user manager is available. Otherwise it uses a marked XDG autostart entry. Disabling autostart removes only files with the package marker. If the distribution already provides the KDE Connect XDG entry, disabling creates a marked user override instead of changing the system file.

External commands use validated executable paths and argument arrays. There is no shell evaluation. Process output is bounded, device identifiers are validated, operations have timeouts, and file or text sharing requires confirmation. The helper does not log device names, file paths, or shared text.

All interface and settings text is translated into English, Russian, and Spanish through Ambxst's localization service. Before the mod is enabled, its settings use readable English because disabled packages cannot register translations. After activation and reload, the settings follow the Ambxst language. The settings patch only routes schema labels, descriptions, and enum choices through the existing `I18n` service. It contains no mod-manager backend, update, or recovery code.
