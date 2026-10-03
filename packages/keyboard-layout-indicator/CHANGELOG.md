# Changelog

## 1.2.1 - 2026-10-03

- Align the on-screen card to physical pixels and render its text above the shadow layer, so longer layout names stay sharp.

## 1.2.0 - 2026-10-03

- Show the active layout for one second after a keyboard shortcut changes it, including XKB switches that Hyprland does not report as events.
- Add capsule, OSD card, and large tile appearances. The OSD card is the default.
- Configure screen position, language code or layout name, background opacity, and whether the on-screen display is enabled in Shell System settings.
- Default to the localized layout name at the bottom center of the screen with 72% background opacity.
- Translate the new settings and common layout names in English, Russian, and Spanish.
- Keep the existing bar button and layout picker unchanged.

## 1.1.1 - 2026-09-22

- Declare English, Russian, and Spanish interface support through Ambxst's translation service.
- Include release notes for the mod manager's update preview.
- Declare `sh` and `awk`, used to read keyboard layout names from the system XKB rules.
