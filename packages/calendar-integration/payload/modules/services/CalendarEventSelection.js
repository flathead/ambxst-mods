.pragma library

function localDate(value) {
    if (typeof value !== "string") return null;
    const parts = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (!parts) return null;
    const year = Number(parts[1]);
    const month = Number(parts[2]) - 1;
    const day = Number(parts[3]);
    const date = new Date(0);
    date.setHours(0, 0, 0, 0);
    date.setFullYear(year, month, day);
    if (date.getFullYear() !== year || date.getMonth() !== month || date.getDate() !== day)
        return null;
    return date;
}

function allDayRange(event) {
    const start = localDate(event.start);
    if (!start) return null;
    let end;
    if (event.end) {
        end = localDate(event.end);
    } else {
        end = new Date(start.getTime());
        end.setDate(end.getDate() + 1);
    }
    // Google Calendar and CalDAV use an exclusive end date for all-day events.
    if (!end || end.getTime() <= start.getTime()) return null;
    return { start: start, end: end };
}

function nextEvent(events, includeAllDay, now) {
    const nowTime = now.getTime();
    if (!isFinite(nowTime)) return null;
    let closest = null;
    let closestTime = Infinity;
    for (const event of events) {
        if (!event || !event.start) continue;
        const allDay = event.allDay === true;
        if (allDay && !includeAllDay) continue;
        const range = allDay ? allDayRange(event) : {
            start: new Date(event.start),
            end: new Date(event.end || event.start)
        };
        if (!range) continue;
        const start = range.start.getTime();
        const end = range.end.getTime();
        if (!isFinite(start) || !isFinite(end) || end < start) continue;
        const active = start <= nowTime && nowTime < end;
        const diff = active ? 0 : start - nowTime;
        // An all-day event expires at local midnight on its exclusive end date.
        if (diff < 0 || (allDay && !active && diff === 0)) continue;
        // A meeting in progress takes priority over an active all-day event.
        if (diff < closestTime || (diff === closestTime && closest && closest.allDay && !allDay)) {
            closest = event;
            closestTime = diff;
        }
    }
    return closest;
}
