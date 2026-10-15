/// Serializes a device-local wall-clock [DateTime] as an ISO-8601 string WITH
/// the device's UTC offset (e.g. `2026-10-15T00:00:00.000+03:00`).
///
/// Plain [DateTime.toIso8601String] omits the offset, and servers parse such
/// strings as UTC — silently shifting every date by the UTC offset. Always
/// use this when sending user-picked dates to the backend.
String toOffsetIso8601String(DateTime local) {
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${local.toIso8601String()}$sign$hours:$minutes';
}
