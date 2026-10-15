const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname,
    '../payload/modules/services/CalendarEventSelection.js'), 'utf8');
const selection = vm.createContext({ Date });
vm.runInContext(source.replace(/^\.pragma library\s*/, ''), selection);
const now = () => new Date(2026, 9, 15, 12);
const allDay = (start = '2026-10-15', end = '2026-10-16') =>
    ({ id: 'all-day', allDay: true, start, end });
const timed = (hour = 14, endHour = hour + 1) =>
    ({ id: 'meeting', start: new Date(2026, 9, 15, hour).toISOString(),
        end: new Date(2026, 9, 15, endHour).toISOString() });
const pick = (events, enabled = true, time = now()) => selection.nextEvent(events, enabled, time);

test('keeps timed-only behavior until the user enables all-day events', () => {
    const meeting = timed();
    assert.equal(pick([allDay(), meeting], false), meeting);
    assert.equal(pick([allDay()], false), null);
});

test('shows an active all-day event before a future timed event', () => {
    const event = allDay();
    assert.equal(pick([timed(), event]), event);
});

test('gives a meeting in progress priority in either input order', () => {
    const meeting = timed(11, 13);
    assert.equal(pick([allDay(), meeting]), meeting);
    assert.equal(pick([meeting, allDay()]), meeting);
});

test('moves back to the all-day event after a meeting ends', () => {
    const event = allDay();
    assert.equal(pick([timed(10, 12), event]), event);
});

test('compares future all-day dates with timed event start times', () => {
    const tomorrow = allDay('2026-10-16', '2026-10-17');
    const tonight = timed(23);
    assert.equal(pick([tomorrow, tonight]), tonight);
    const nextMorning = { start: new Date(2026, 9, 16, 9).toISOString() };
    assert.equal(pick([nextMorning, tomorrow]), tomorrow);
});

test('honors the exclusive end date of a multi-day event', () => {
    const event = allDay('2026-10-13', '2026-10-16');
    assert.equal(pick([event]), event);
    assert.equal(pick([event], true, new Date(2026, 9, 16)), null);
});

test('uses local calendar dates across midnight', () => {
    const event = allDay();
    assert.equal(pick([event], true, new Date(2026, 9, 15, 0, 1)), event);
    assert.equal(pick([event], true, new Date(2026, 9, 15, 23, 59)), event);
    assert.equal(pick([event], true, new Date(2026, 9, 16)), null);
});

test('treats a missing end as one local calendar day', () => {
    const event = allDay('2026-10-15', '');
    assert.equal(pick([event]), event);
    assert.equal(pick([event], true, new Date(2026, 9, 16)), null);
});

test('handles year rollover and leap day', () => {
    const event = allDay('2024-02-29', '');
    const leapRange = selection.allDayRange(event);
    assert.equal(leapRange.end.getMonth(), 2);
    assert.equal(leapRange.end.getDate(), 1);
    const yearRange = selection.allDayRange(allDay('2026-12-31', ''));
    assert.equal(yearRange.end.getFullYear(), 2027);
    assert.equal(yearRange.end.getMonth(), 0);
    assert.equal(yearRange.end.getDate(), 1);
});

test('uses calendar days across daylight-saving changes', () => {
    for (const date of ['2026-03-08', '2026-11-01']) {
        const range = selection.allDayRange(allDay(date, ''));
        assert.equal(range.start.getDate() + 1, range.end.getDate());
        assert.equal(range.end.getHours(), 0);
        const noon = new Date(range.start.getTime());
        noon.setHours(12);
        assert.equal(pick([allDay(date, '')], true, noon).start, date);
    }
    if (process.env.TZ === 'America/New_York') {
        const spring = selection.allDayRange(allDay('2026-03-08', ''));
        const autumn = selection.allDayRange(allDay('2026-11-01', ''));
        assert.equal((spring.end - spring.start) / 3600000, 23);
        assert.equal((autumn.end - autumn.start) / 3600000, 25);
    }
});

test('skips invalid dates and ranges without hiding a valid event', () => {
    const meeting = timed();
    const broken = [null, {}, allDay('2026-02-30'), allDay('2025-02-29'),
        allDay('2026-13-01'), allDay('2026-10-15', 'bad'),
        allDay('2026-10-15', '2026-10-15'), allDay('2026-10-16', '2026-10-15'),
        { start: 'bad' }, { start: now().toISOString(), end: 'bad' }, timed(15, 14)];
    assert.equal(pick([...broken, meeting]), meeting);
});

test('does not select expired timed events and handles an empty calendar', () => {
    assert.equal(pick([timed(8, 9)]), null);
    assert.equal(pick([]), null);
    assert.equal(pick([allDay()], true, new Date('invalid')), null);
});

test('selects an event that starts at the current time', () => {
    const meeting = timed(12, 13);
    assert.equal(pick([allDay(), meeting]), meeting);
});
