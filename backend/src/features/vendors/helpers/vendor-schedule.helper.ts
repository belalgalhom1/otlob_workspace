interface RawWorkingHoursEntry {
  day?: number | string;
  isClosed?: boolean | string;
  openTime?: unknown;
  closeTime?: unknown;
}

interface ParsedScheduleEntry {
  isClosed: boolean;
  openMinutes: number;
  closeMinutes: number;
}

function parseScheduleEntry(entry: RawWorkingHoursEntry): ParsedScheduleEntry {
  const isClosed = entry.isClosed === true || entry.isClosed === 'true';
  const openTimeStr =
    typeof entry.openTime === 'string' ? entry.openTime : '09:00';
  const closeTimeStr =
    typeof entry.closeTime === 'string' ? entry.closeTime : '22:00';

  const [openHour, openMin] = openTimeStr.split(':').map(Number);
  const [closeHour, closeMin] = closeTimeStr.split(':').map(Number);

  return {
    isClosed,
    openMinutes: openHour * 60 + openMin,
    closeMinutes: closeHour * 60 + closeMin,
  };
}

/**
 * Evaluate whether a vendor is currently open given its weekly `workingHours`
 * JSON schedule in Egypt time (`Africa/Cairo`), including overnight shifts
 * that spill from yesterday into early this morning. Fails closed on
 * malformed JSON schedules.
 */
export function isVendorScheduleOpen(
  workingHours: unknown,
  referenceNow: Date = new Date(),
): boolean {
  if (
    !workingHours ||
    !Array.isArray(workingHours) ||
    workingHours.length === 0
  ) {
    return true;
  }

  try {
    const cairoTimeStr = referenceNow.toLocaleString('en-US', {
      timeZone: 'Africa/Cairo',
    });
    const cairoNow = new Date(cairoTimeStr);
    const todayDay = cairoNow.getDay();
    const currentMinutes = cairoNow.getHours() * 60 + cairoNow.getMinutes();

    const entries = workingHours as RawWorkingHoursEntry[];

    // 1. Check yesterday's schedule for an overnight shift spilling past 00:00
    const yesterdayDay = (todayDay + 6) % 7;
    const yesterdayRaw = entries.find((h) => Number(h.day) === yesterdayDay);
    if (yesterdayRaw) {
      const y = parseScheduleEntry(yesterdayRaw);
      if (
        !y.isClosed &&
        y.closeMinutes <= y.openMinutes &&
        currentMinutes <= y.closeMinutes
      ) {
        return true;
      }
    }

    // 2. Check today's schedule
    const todayRaw = entries.find((h) => Number(h.day) === todayDay);
    if (!todayRaw) return true;

    const t = parseScheduleEntry(todayRaw);
    if (t.isClosed) return false;

    if (t.closeMinutes === t.openMinutes) {
      return true;
    }

    if (t.closeMinutes < t.openMinutes) {
      return currentMinutes >= t.openMinutes;
    }

    return (
      currentMinutes >= t.openMinutes && currentMinutes <= t.closeMinutes
    );
  } catch {
    return false;
  }
}
