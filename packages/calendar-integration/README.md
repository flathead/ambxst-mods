# Calendar integration

Connect Google Calendar or CalDAV accounts to see events in the dashboard and
bar. The mod supports Ambxst 1.3.x starting with 1.3.8.

## All-day events in the bar

Open **Settings > System > Calendar > Settings**. Enable **Bar indicator** and
**Show next upcoming event**, then enable **Include all-day events** and save.
The new setting starts off for existing and new installations.

The bar shows an active all-day event before future meetings. A meeting in
progress takes priority. The bar shows **All day** for an active all-day event;
for a future one, it adds the start date. Multi-day events stay eligible through
their final day. The provider's end date is exclusive, so an event ending on
Friday disappears at the start of Friday in your local time zone.

The vertical bar keeps its event-count layout. Open its popup to read event
titles. All-day inclusion applies to the horizontal upcoming-event display.

## Update

Update **Calendar integration** in Ambxst's mod manager, then restart the shell.
Version 1.2.0 includes all-day events as an option. The package keeps the same
ID, `community.calendar-integration`.

## Tests

Run date selection tests from the repository root:

```bash
for timezone in UTC Europe/Moscow America/New_York Pacific/Honolulu; do
  TZ="$timezone" node --test packages/calendar-integration/tests/selection.test.cjs
done
```

CI runs these cases with the composition checks. The tests cover all-day and
timed event priority, midnight, exclusive end dates, daylight-saving changes,
missing end dates and invalid input.

After composing this package, check the QML controls and bar:

```bash
python3 scripts/check-calendar-qml.py --source /path/to/composed/Ambxst
```

That check loads the package's CalendarPanel, CalendarService and bar indicator
in Quickshell with a temporary settings file. It exercises the keyboard toggle,
Save and reset behavior, event changes and labels in English, Russian and
Spanish. It stubs theme and container components and leaves the provider
process stopped.
