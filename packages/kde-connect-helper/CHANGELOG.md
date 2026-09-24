# Changelog

## 1.0.4

- Follow the bar button's actual four-corner geometry with the battery progress outline.
- Show the device name with its percentage in the detailed battery-oriented mode.
- Draw only the measured battery fraction instead of relying on unsupported dashed Canvas strokes.
- Add configurable yellow warning and red low-battery ranges.
- Apply the icon, device, status, and battery content selector to compact buttons.
- Make the hide option remove the separate KDE Connect system tray icon.
- Use the desktop portal to select and confirm one or more files.

## 1.0.3

- Draw battery progress clockwise around the native button surface instead of using a circular badge.
- Keep the phone icon inside the button and place the percentage in a stable text slot.
- Collapse detailed buttons when their text is hidden or unavailable instead of leaving an empty surface.
- Use the theme-defined foreground color for selected and pressed popup actions.

## 1.0.2

- Keep the helper button at its intended size when loaded into horizontal or vertical bars.
- Match Ambxst bar controls for background, hover feedback, active colors, radii, and popup anchoring.
- Give native mod settings fields distinct resting, hover, and focus surfaces.
- Keep action results visible after the follow-up status scan.
- Explain when the daemon executable is missing.
- Prevent package installation from inheriting the command-output file limit.
- Restrict privileged package installation to fixed, root-owned system executables.

## 1.0.1

- Show readable English settings before the mod is enabled.
- Translate settings into Russian and Spanish after activation and reload.

## 1.0.0

- Add a responsive KDE Connect bar button and helper popup.
- Add structured D-Bus device discovery, battery status, and supported device actions.
- Add confirmed Arch and Fedora installation flows plus declarative NixOS guidance.
- Add user-level systemd and XDG autostart controls.
- Add reactive mod settings, including the option to hide the KDE Connect label.
- Add complete English, Russian, and Spanish interface translations.
