// ─── App timezone ──────────────────────────────────────────────────────────
// Single source of truth for every wall-clock interpretation in the backend.
// Set TIMEZONE in .env (e.g. TIMEZONE=Africa/Cairo). Everything date-related
// — shift wall-clock composition, statistics day buckets, date-only filters —
// goes through these helpers, so changing the env var moves the whole system.

let cachedZone: string | null = null;

/** IANA timezone from .env, validated once, falling back to UTC. */
export function appTimeZone(): string {
  if (cachedZone) return cachedZone;
  const raw = (process.env.TIMEZONE || 'UTC').trim();
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: raw });
    cachedZone = raw;
  } catch {
    cachedZone = 'UTC';
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
  return new Date(
    wallToUtc(year, month, day, 23, 59, tz).getTime() + 59999,
  );
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
