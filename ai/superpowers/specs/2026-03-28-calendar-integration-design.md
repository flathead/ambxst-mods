# Calendar Integration Design

## Context

Ambxst's dashboard has a calendar widget showing a monthly grid, but it's static — no event integration. Users need to see their schedule, manage events, and get reminders directly from the shell. This spec covers integrating Google Calendar and CalDAV providers with two-way sync, event management UI, D-Bus notifications, and a bar indicator.

## Architecture

Single long-running Python process (`calendar_service.py`), matching the `system_monitor.py` pattern. QML communicates via stdin (commands) / stdout (JSON lines). One QML Singleton service (`CalendarService.qml`) manages the process and exposes events to UI components.

```
QML (CalendarService.qml)
  │ stdin: commands (JSON)
  │ stdout: data (JSON lines)
  ▼
Python (calendar_service.py)
  │ OAuth 2.0 / CalDAV
  ▼
Google Calendar API / CalDAV servers
```

## Providers

- **Google Calendar**: OAuth 2.0 Device Flow or localhost redirect. Libraries: `google-auth`, `google-api-python-client`.
- **CalDAV**: Standard protocol. Libraries: `caldav`, `icalendar`. Supports Nextcloud, Radicale, Baikal, and any CalDAV-compliant server.

## Protocol (QML ↔ Python)

### Commands (QML → Python via stdin)

```json
{"cmd": "sync"}
{"cmd": "create", "event": {"calendarId": "...", "title": "...", "start": "...", "end": "...", "allDay": false, "reminder": 15, "description": ""}}
{"cmd": "update", "event": {"id": "...", "calendarId": "...", "title": "...", "start": "...", "end": "...", "allDay": false, "reminder": 15, "description": ""}}
{"cmd": "delete", "eventId": "...", "calendarId": "..."}
{"cmd": "auth_google"}
{"cmd": "auth_caldav", "url": "...", "user": "...", "pass": "..."}
{"cmd": "remove_account", "accountId": "..."}
```

### Responses (Python → QML via stdout)

```json
{"type": "static", "accounts": [...], "calendars": [...]}
{"type": "events", "data": [...]}
{"type": "auth_complete", "provider": "google|caldav", "account": {...}}
{"type": "auth_error", "message": "..."}
{"type": "notify", "event": {...}}
{"type": "error", "message": "..."}
{"type": "sync_status", "syncing": true|false}
```

## Data Model

### Cache file: `~/.cache/ambxst/calendar_events.json`

```json
{
  "last_sync": "2026-03-28T10:00:00Z",
  "accounts": [
    {"id": "google_user@gmail.com", "provider": "google", "email": "user@gmail.com"}
  ],
  "calendars": [
    {"id": "cal1", "accountId": "google_user@gmail.com", "name": "Work", "color": "#ff79c6", "enabled": true}
  ],
  "events": [
    {
      "id": "evt1",
      "calendarId": "cal1",
      "title": "Standup",
      "description": "",
      "start": "2026-03-28T09:00:00",
      "end": "2026-03-28T09:30:00",
      "allDay": false,
      "reminder": 15
    }
  ]
}
```

### Credentials: `~/.config/ambxst/calendar_tokens.json`

Stores OAuth tokens and CalDAV credentials. File permissions 600. Encrypted via system keyring if available, plaintext fallback.

## New Files

| File | Purpose |
|------|---------|
| `modules/services/CalendarService.qml` | Singleton service. Manages Python process, stores events, provides API to UI |
| `scripts/calendar_service.py` | Python backend: OAuth, CalDAV, CRUD, cache, D-Bus notifications |
| `modules/widgets/dashboard/widgets/calendar/EventPopup.qml` | Day popup: event list + create/edit form |
| `modules/widgets/dashboard/widgets/calendar/EventItem.qml` | Single event row component |
| `modules/widgets/dashboard/controls/CalendarPanel.qml` | Settings panel: accounts, calendars, preferences |
| `modules/bar/BarCalendarIndicator.qml` | Bar widget: next event preview + today's events popup |
| `config/defaults/calendar.js` | Default config values |

## Modified Files

| File | Change |
|------|--------|
| `modules/widgets/dashboard/widgets/calendar/Calendar.qml` | Day click → EventPopup; event indicators on days |
| `modules/widgets/dashboard/widgets/calendar/CalendarDayButton.qml` | Colored dots under day numbers for days with events |
| `modules/bar/BarContent.qml` | Add BarCalendarIndicator Loader |
| `config/Config.qml` | Add `calendar` config section |
| `modules/widgets/dashboard/controls/SystemPanel.qml` | Add calendar settings link/section |

## UI Components

### Calendar Day Indicators

Small colored dots under day numbers. Each dot corresponds to a calendar's color. Multiple dots for events from multiple calendars. Max 3 dots visible (overflow hidden).

### EventPopup (day click)

Two modes in one popup:

**List mode** (default):
- Header: date + event count + "+ Add" button
- Event rows: color bar | title | time range | calendar source
- Click event → switch to edit mode
- Click "+ Add" → switch to create mode

**Edit/Create mode**:
- Title input
- Start/End time inputs
- Calendar selector dropdown
- Reminder selector dropdown (none, 5/10/15/30/60 min, 1 day)
- Description textarea
- Save + Delete buttons (Delete hidden in create mode)
- Cancel (✕) → back to list mode

Popup width: 320px. Positioned relative to clicked day cell.

### BarCalendarIndicator

**Chip (horizontal bar)**: Calendar icon + event title + "in X min" countdown. Shows next upcoming event. Hidden when no events today.

**Chip (vertical bar)**: Calendar icon above, time until event below. Same as resource monitor pattern.

**Popup (click)**: Today's events list with colored bars, times, and countdown for upcoming. Width: 280px.

### CalendarPanel (settings)

Accessed via ⚙ button next to month name, or through dashboard settings menu.

Sections:
1. **Connected Accounts** — list with provider icon, email/name, status, Remove button. "+ Google" and "+ CalDAV" buttons.
2. **Calendars** — per-calendar toggle switches with color dots and source label.
3. **Settings** — sync interval (5/15/30/60 min), notifications toggle, bar indicator toggle, default reminder.

## Authentication

### Google Calendar OAuth

1. User clicks "+ Google" in CalendarPanel
2. QML sends `{"cmd": "auth_google"}`
3. Python starts localhost HTTP server for OAuth redirect
4. Python opens browser via `xdg-open` with Google authorization URL
5. User authorizes → redirect to localhost → Python captures auth code
6. Python exchanges code for tokens, stores in `calendar_tokens.json`
7. Python sends `{"type": "auth_complete", "provider": "google", ...}`

Required scopes: `https://www.googleapis.com/auth/calendar`

### CalDAV

1. User enters server URL, username, password in CalendarPanel form
2. QML sends `{"cmd": "auth_caldav", "url": "...", "user": "...", "pass": "..."}`
3. Python validates connection, discovers calendars via PROPFIND
4. Credentials stored in `calendar_tokens.json`

## Notifications

- Python tracks event reminder times in background
- At reminder time: sends D-Bus notification via `notify-send` (title, time, calendar name)
- Also sends `{"type": "notify", "event": {...}}` to QML for bar indicator update
- Bar indicator highlights/pulses briefly when notification fires
- Notifications respect the `notifications` toggle in settings

## Process Lifecycle

- Starts on Quickshell launch if any accounts are configured
- Does NOT start if no accounts connected (unlike system_monitor which always runs)
- Periodic sync at `syncInterval` (default 15 min)
- Receives commands via stdin for real-time CRUD operations
- On CRUD: immediately updates local cache, then syncs to server
- Graceful shutdown on SIGTERM

## Config Defaults (`config/defaults/calendar.js`)

```javascript
{
  "enabled": true,
  "syncInterval": 15,
  "notifications": true,
  "barIndicator": true,
  "defaultReminder": 15,
  "accounts": [],
  "calendars": {}
}
```

## Error Handling

- Network failure during sync: use cached data, show subtle error state, retry on next interval
- OAuth token expiry: auto-refresh; if refresh fails, mark account as "needs re-auth"
- CalDAV auth failure: mark account as disconnected, notify user
- CRUD failure: revert local cache, show error in popup

## Verification

1. Start Quickshell, open dashboard → calendar should show with no accounts (empty state)
2. Click ⚙ → CalendarPanel → add Google account → authorize in browser → verify account appears
3. Events from Google Calendar should appear as colored dots on calendar days
4. Click a day with events → EventPopup shows event list
5. Create new event → verify it syncs to Google Calendar
6. Edit event → verify changes sync
7. Delete event → verify removal syncs
8. Add CalDAV account → verify events from both sources appear
9. Check bar indicator shows next upcoming event
10. Wait for reminder time → verify D-Bus notification fires
11. Toggle calendar off in settings → verify its events hide from calendar
12. Disconnect internet → verify cached events still display
