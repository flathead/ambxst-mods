# App launcher reliability

Repair for DesktopEntry replacement during Quickshell 0.3.2 rescans. Launch
callbacks keep IDs instead of deleted objects. Dock lookups observe registry
changes. Exact application identity takes precedence over shared executables.

Supports Ambxst 1.3.x starting with 1.3.9. The package retains its initial
`local.app-launcher-reliability` ID so existing installations update in place.

```bash
ambxst mods install https://github.com/flathead/ambxst-mods/tree/main/packages/app-launcher-reliability
ambxst mods enable local.app-launcher-reliability
ambxst reload
```

Run the regression test from the repository root:

```bash
python3 scripts/check-launcher.py --source /path/to/Ambxst
```

The test runs the actual patched AppSearch service in Quickshell with isolated
XDG directories. It changes an overridden desktop file after results have been
cached, verifies both Steam and game icons, and checks that saved launcher and
search callbacks both execute the new command. It does not start Steam or
modify the user's application directories.
