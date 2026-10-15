# Changelog

## 1.2.0 - 2026-10-15

- Add **Include all-day events** under Settings > System > Calendar > Settings. Enable **Show next upcoming event** to use it.
- Show active all-day events before future meetings. Give meetings in progress priority.
- Show **All day** for an active event and its date for a future event. Respect local dates and exclusive end dates for multi-day events.
- Refresh the selected event and today's list on the bar's clock tick.
- Add date-selection tests and QML checks for keyboard input, settings persistence and translated labels.

## 1.1.4 - 2026-10-15

- Initialize calendar defaults independently of the base preset copier, preserving compatibility with Ambxst 1.3.8 through 1.3.12.

## 1.1.3 - 2026-09-25

- Move Calendar settings to System > Calendar. The mod no longer adds a Settings sidebar entry, so it cannot take another mod's position.
- Open System > Calendar from the dashboard calendar on stock Ambxst builds.
- Point settings search results at System > Calendar.
- Drop whitespace-only edits from the patch to reduce conflicts with other mods.

## 1.1.2 - 2026-09-25

- Keep Calendar in the penultimate Settings menu position.
- Open Calendar settings by its resolved menu position instead of a fixed index.

## 1.1.1 - 2026-09-22

- Declare English, Russian, and Spanish interface support through Ambxst's translation service.
- Include release notes for the mod manager's update preview.
- Declare `xdg-open` and browser access for event and meeting links.
- Document optional gcalcli credential access and provider-specific Python dependencies.
