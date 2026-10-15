# Compatibility, 2026-10-15

The latest upstream release and `dev` both resolve to Ambxst 1.3.12,
`1e1a56493582f34e5e5593bc9d3c2f87246266fb`, on this date.

| Package | Package version | Source releases checked |
| --- | --- | --- |
| Audio device switcher | 1.1.2 | 1.3.8–1.3.12 |
| Bar resource monitor | 1.1.3 | 1.3.8–1.3.12 |
| Calendar integration | 1.1.4 | 1.3.8–1.3.12 |
| KDE Connect helper | 1.0.10 | 1.3.8–1.3.12 |
| Keyboard layout indicator | 1.2.3 | 1.3.8–1.3.12 |
| Volume scroll | 1.1.2 | 1.3.8–1.3.12 |
| OCR text selection | 1.0.1 | 1.3.9–1.3.12 |
| App launcher reliability | 1.0.0 | 1.3.9–1.3.12 |

The native 1.3.12 manager composes every package individually and the complete
supported set on each source release. It uses temporary source checkouts and
isolated config, data, state, cache and runtime directories. No compatibility
bypass is used. The [JSON report](compatibility-2026-10-15.json) records exact
base revisions and results. Packages requiring 1.3.9 are excluded from the
1.3.8 combined case.

These results verify source composition with the current manager; they do not
claim runtime testing of each historical binary. The complete installed set,
including the locally adapted third-party Roadie package, was loaded in the
real 1.3.12 Wayland session. Steam launched from the launcher and completed its
own update. Source composition does not verify every UI state or eliminate
unrelated pre-existing panel warnings.

Thirty Python helper tests passed locally, including real multilingual OCR.
The Quickshell regression test for launcher reliability passed six icon and
registry assertions and verified that both saved launch callbacks used the
updated desktop command.

CI repeats the composition and helper checks on repository changes and weekly.
It checks the latest stable tag and current `dev` in addition to these known
releases. The Quickshell runtime regression is run locally with
`scripts/check-launcher.py`; CI's source-composition result is not a substitute
for that runtime check. New upstream releases may still require adaptation;
compatibility ranges and checked revisions are recorded separately.
