// ─── App timezone ──────────────────────────────────────────────────────────
// Single source of truth for every wall-clock interpretation in the backend.
// Set TIMEZONE in .env (e.g. TIMEZONE=Africa/Cairo). Everything date-related
// — shift wall-clock composition, statistics day buckets, date-only filters —
// goes through these helpers, so changing the env var moves the whole system.

let cachedZone: string | null = null;

/** IANA timezone from .env, validated once, falling back to UTC. */
export function appTimeZone(): string {
  if (cachedZone) return cachedZone;
  const raw = (process.env.TIMEZONE || 'Africa/Cairo').trim();
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: raw });
    cachedZone = raw;
  } catch {
    cachedZone = 'Africa/Cairo';
  }
  return cachedZone;
}

interface TzFormatters {
  offset: Intl.DateTimeFormat;
  parts: Intl.DateTimeFormat;
}

const formatterCache = new Map<string, TzFormatters>();

function formatters(tz: string): TzFormatters {
  let cached = formatterCache.get(tz);
  if (!cached) {
    cached = {
      offset: new Intl.DateTimeFormat('en-US', {
        timeZone: tz,
        hourCycle: 'h23',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      }),
      parts: new Intl.DateTimeFormat('en-US', {
        timeZone: tz,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        weekday: 'short',
      }),
    };
    formatterCache.set(tz, cached);
  }
  return cached;
}

/** Minutes east of UTC for the app timezone at the given instant. */
export function tzOffsetMinutes(instant: Date, tz = appTimeZone()): number {
  const dtf = formatters(tz).offset;
  const parts = Object.fromEntries(
    dtf.formatToParts(instant).map((p) => [p.type, p.value]),
  );
  const asUtc = Date.UTC(
    Number(parts.year),
    Number(parts.month) - 1,
    Number(parts.day),
    Number(parts.hour),
    Number(parts.minute),
    Number(parts.second),
  );
  return Math.round((asUtc - instant.getTime()) / 60000);
}

/**
 * Interprets a calendar day + "HH:mm" wall-clock pair in the app timezone
 * and returns the corresponding UTC instant. Iterated twice so dates sitting
 * exactly on a DST transition converge to the correct offset.
 */
export function wallToUtc(
  year: number,
  month: number,
  day: number,
  hour: number,
  minute: number,
  tz = appTimeZone(),
): Date {
  let guess = new Date(Date.UTC(year, month - 1, day, hour, minute));
  for (let i = 0; i < 2; i++) {
    guess = new Date(
      Date.UTC(year, month - 1, day, hour, minute) -
        tzOffsetMinutes(guess, tz) * 60000,
    );
  }
  return guess;
}

export interface TzYmd {
  year: number;
  month: number;
  day: number;
  /** 0 = Sunday … 6 = Saturday, for the zoned calendar date. */
  weekday: number;
}

/** Calendar parts of an instant in the app timezone. */
export function tzParts(instant: Date, tz = appTimeZone()): TzYmd {
  const dtf = formatters(tz).parts;
  const parts = Object.fromEntries(
    dtf.formatToParts(instant).map((p) => [p.type, p.value]),
  );
  const year = Number(parts.year);
  const month = Number(parts.month);
  const day = Number(parts.day);
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return { year, month, day, weekday };
}

function pad(n: number): string {
  return String(n).padStart(2, '0');
}

/** "YYYY-MM-DD" label for an instant in the app timezone. */
export function tzDateKey(instant: Date, tz = appTimeZone()): string {
  const p = tzParts(instant, tz);
  return `${p.year}-${pad(p.month)}-${pad(p.day)}`;
}

/** UTC instant of zoned midnight starting the given calendar day. */
export function tzDayStart(
  year: number,
  month: number,
  day: number,
  tz = appTimeZone(),
): Date {
  return wallToUtc(year, month, day, 0, 0, tz);
}

/** UTC instant of the last millisecond of the given zoned calendar day. */
export function tzDayEnd(
  year: number,
  month: number,
  day: number,
  tz = appTimeZone(),
): Date {
  return new Date(wallToUtc(year, month, day, 23, 59, tz).getTime() + 59999);
}

function parseYmd(value: string): TzYmd | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(value.trim());
  if (!m) return null;
  const year = Number(m[1]);
  const month = Number(m[2]);
  const day = Number(m[3]);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  const weekday = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
  return { year, month, day, weekday };
}

/**
 * Parses a date-only "YYYY-MM-DD" filter string as the START of that zoned
 * day. Full ISO strings (with time/offset) pass through to the Date
 * constructor untouched so exact instants keep working.
 */
export function parseDateStart(value: string, tz = appTimeZone()): Date {
  const ymd = parseYmd(value);
  if (!ymd) return new Date(value);
  return tzDayStart(ymd.year, ymd.month, ymd.day, tz);
}

/**
 * Parses a date-only "YYYY-MM-DD" filter string as the END of that zoned day
 * (inclusive). Full ISO strings pass through untouched.
 */
export function parseDateEnd(value: string, tz = appTimeZone()): Date {
  const ymd = parseYmd(value);
  if (!ymd) return new Date(value);
  return tzDayEnd(ymd.year, ymd.month, ymd.day, tz);
}

export interface CairoWeekBounds {
  periodKey: string;
  monday: TzYmd;
  sunday: TzYmd;
  periodStart: Date;
  periodEnd: Date;
}

/** Shifts a zoned calendar date by `deltaDays` without local-timezone drift. */
export function addCalendarDays(
  ymd: Pick<TzYmd, 'year' | 'month' | 'day'>,
  deltaDays: number,
): TzYmd {
  const dt = new Date(Date.UTC(ymd.year, ymd.month - 1, ymd.day + deltaDays));
  return {
    year: dt.getUTCFullYear(),
    month: dt.getUTCMonth() + 1,
    day: dt.getUTCDate(),
    weekday: dt.getUTCDay(),
  };
}

/** Parses an `"HH:mm"` wall-clock string; falls back to `00:05` if blank/invalid. */
export function parseEvalTimeHhMm(value?: string | null): {
  hour: number;
  minute: number;
} {
  const trimmed = (value ?? '').trim();
  const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(trimmed);
  if (!m) return { hour: 0, minute: 5 };
  return { hour: Number(m[1]), minute: Number(m[2]) };
}

/** Normalizes an `"HH:mm"` evaluation time string using `parseEvalTimeHhMm`. */
export function formatEvalTimeHhMm(value?: string | null): string {
  const { hour, minute } = parseEvalTimeHhMm(value);
  return `${pad(hour)}:${pad(minute)}`;
}

/** Standard ISO-8601 week key (`YYYY-Www`) from the week's Monday calendar date. */
export function isoWeekKeyFromMonday(
  monday: Pick<TzYmd, 'year' | 'month' | 'day'>,
): string {
  const thursday = addCalendarDays(monday, 3);
  const isoYear = thursday.year;
  const jan4Utc = Date.UTC(isoYear, 0, 4);
  const jan4MonZeroDay = (new Date(jan4Utc).getUTCDay() + 6) % 7;
  const week1MondayUtc = jan4Utc - jan4MonZeroDay * 86_400_000;
  const mondayUtc = Date.UTC(monday.year, monday.month - 1, monday.day);
  const weekNo = Math.round((mondayUtc - week1MondayUtc) / (7 * 86_400_000)) + 1;
  return `${isoYear}-W${pad(weekNo)}`;
}

/**
 * Returns the Monday 00:00:00.000 -> Sunday 23:59:59.999 week bounds and
 * ISO-8601 periodKey in `tz` for the calendar week containing `instant`.
 */
export function getCairoWeekBounds(
  instant: Date,
  tz = appTimeZone(),
): CairoWeekBounds {
  const p = tzParts(instant, tz);
  const diffToMonday = p.weekday === 0 ? -6 : 1 - p.weekday;
  const monday = addCalendarDays(p, diffToMonday);
  const sunday = addCalendarDays(monday, 6);
  return {
    periodKey: isoWeekKeyFromMonday(monday),
    monday,
    sunday,
    periodStart: tzDayStart(monday.year, monday.month, monday.day, tz),
    periodEnd: tzDayEnd(sunday.year, sunday.month, sunday.day, tz),
  };
}

/**
 * Returns the previous completed Monday->Sunday calendar week relative to `now`
 * in `tz`. Never returns the active in-progress week.
 */
export function getPreviousCompletedCairoWeek(
  now: Date,
  tz = appTimeZone(),
): CairoWeekBounds {
  const currentWeek = getCairoWeekBounds(now, tz);
  const monday = addCalendarDays(currentWeek.monday, -7);
  const sunday = addCalendarDays(monday, 6);
  return {
    periodKey: isoWeekKeyFromMonday(monday),
    monday,
    sunday,
    periodStart: tzDayStart(monday.year, monday.month, monday.day, tz),
    periodEnd: tzDayEnd(sunday.year, sunday.month, sunday.day, tz),
  };
}

/**
 * Scheduled evaluation instant for `getPreviousCompletedCairoWeek(now)`:
 * Monday of the current week at `hhMm` in `tz`.
 */
export function getScheduledEvaluationUtcForCompletedWeek(
  now: Date,
  hhMm?: string | null,
  tz = appTimeZone(),
): Date {
  const currentWeek = getCairoWeekBounds(now, tz);
  const { hour, minute } = parseEvalTimeHhMm(hhMm);
  return wallToUtc(
    currentWeek.monday.year,
    currentWeek.monday.month,
    currentWeek.monday.day,
    hour,
    minute,
    tz,
  );
}

/**
 * Computes the next scheduled weekly evaluation timestamp in UTC.
 * Only schedules on Mondays (either today if today is Monday in `tz` and the
 * previous completed week has not been evaluated yet and either evalTime is still
 * ahead or auto-eval is enabled, otherwise next Monday). Never returns a past
 * timestamp on Tuesday-Sunday.
 */
export function getNextScheduledEvaluationUtc(
  now: Date,
  hhMm?: string | null,
  previousWeekAlreadyEvaluated = false,
  tz = appTimeZone(),
  autoEvalEnabled = true,
): Date {
  const currentWeek = getCairoWeekBounds(now, tz);
  const { hour, minute } = parseEvalTimeHhMm(hhMm);
  const thisMondayAt = wallToUtc(
    currentWeek.monday.year,
    currentWeek.monday.month,
    currentWeek.monday.day,
    hour,
    minute,
    tz,
  );
  const nowParts = tzParts(now, tz);
  const isMonday = nowParts.weekday === 1;
  if (
    !previousWeekAlreadyEvaluated &&
    isMonday &&
    (now.getTime() < thisMondayAt.getTime() || autoEvalEnabled)
  ) {
    return thisMondayAt;
  }

  const nextMonday = addCalendarDays(currentWeek.monday, 7);
  return wallToUtc(
    nextMonday.year,
    nextMonday.month,
    nextMonday.day,
    hour,
    minute,
    tz,
  );
}

/**
 * Parses a YYYY-MM-DD (or ISO timestamp) string into a UTC-midnight Date
 * matching `@db.Date` columns without server-local timezone drift.
 */
export function parseUtcDateOnly(dateInput: string): Date {
  const ymdPart = dateInput.trim().slice(0, 10);
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymdPart);
  if (match) {
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    return new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
  }
  const parsed = new Date(dateInput);
  return new Date(
    Date.UTC(
      parsed.getUTCFullYear(),
      parsed.getUTCMonth(),
      parsed.getUTCDate(),
      0,
      0,
      0,
      0,
    ),
  );
}

/**
 * Returns 23:59:59.999 UTC for the given YYYY-MM-DD (or ISO timestamp) string.
 */
export function endOfUtcDateOnly(dateInput: string): Date {
  const start = parseUtcDateOnly(dateInput);
  return new Date(start.getTime() + 86_400_000 - 1);
}
