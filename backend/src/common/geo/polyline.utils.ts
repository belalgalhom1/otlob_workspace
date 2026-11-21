import { GeoPoint, haversineKm } from './geo.utils';

/**
 * Validates whether an unknown value represents a finite WGS84 GeoPoint.
 */
export function isValidGeoPoint(value: unknown): value is GeoPoint {
  if (!value || typeof value !== 'object') return false;
  const candidate = value as { lat?: unknown; lng?: unknown };
  const lat = Number(candidate.lat);
  const lng = Number(candidate.lng);
  return (
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

/**
 * Returns true when coordinates represent a meaningful non-(0,0) location.
 */
export function isNonZeroGeoPoint(point: GeoPoint): boolean {
  return Math.abs(point.lat) > 0.0001 || Math.abs(point.lng) > 0.0001;
}

/**
 * Extracts a WGS84 GeoPoint from any supported backend/GeoJSON shape:
 * - `{ type: 'Point', coordinates: [lng, lat] }` or `{ coordinates: [lng, lat] }`
 * - `{ latitude, longitude }`
 * - `{ lat, lng }`
 * - `[lng, lat]`
 *
 * Returns `null` for malformed coordinates or `(0, 0)` placeholder points.
 */
export function extractGeoPointFromUnknown(raw: unknown): GeoPoint | null {
  if (!raw) return null;

  let lat: number | undefined;
  let lng: number | undefined;

  if (Array.isArray(raw) && raw.length >= 2) {
    lng = Number(raw[0]);
    lat = Number(raw[1]);
  } else if (typeof raw === 'object') {
    const obj = raw as Record<string, unknown>;
    if (Array.isArray(obj.coordinates) && obj.coordinates.length >= 2) {
      lng = Number(obj.coordinates[0]);
      lat = Number(obj.coordinates[1]);
    } else if (obj.latitude !== undefined && obj.longitude !== undefined) {
      lat = Number(obj.latitude);
      lng = Number(obj.longitude);
    } else if (obj.lat !== undefined && obj.lng !== undefined) {
      lat = Number(obj.lat);
      lng = Number(obj.lng);
    }
  }

  if (lat === undefined || lng === undefined) return null;
  const point: GeoPoint = { lat, lng };
  if (!isValidGeoPoint(point) || !isNonZeroGeoPoint(point)) return null;
  return point;
}

/**
 * Collapses adjacent waypoints separated by less than [minDistanceKm] while
 * keeping at least `[first, last]` when distinct endpoints exist so short-hop
 * routes never degenerate into empty geometry.
 */
export function deduplicateAdjacentWaypoints(
  waypoints: readonly GeoPoint[],
  minDistanceKm = 0.015,
): GeoPoint[] {
  const valid = waypoints.filter(isValidGeoPoint);
  if (valid.length <= 1) return [...valid];

  const kept: GeoPoint[] = [valid[0]];
  for (let i = 1; i < valid.length; i++) {
    const prev = kept[kept.length - 1];
    const current = valid[i];
    if (haversineKm(prev, current) >= minDistanceKm) {
      kept.push(current);
    }
  }

  // Preserve distinct final destination if all intermediate points were collapsed
  const lastInput = valid[valid.length - 1];
  const lastKept = kept[kept.length - 1];
  if (kept.length === 1 && haversineKm(lastKept, lastInput) > 0.0005) {
    kept.push(lastInput);
  } else if (
    kept.length >= 2 &&
    haversineKm(lastKept, lastInput) >= minDistanceKm
  ) {
    kept.push(lastInput);
  }

  return kept;
}

function encodeSignedValue(value: number): string {
  let encoded = value < 0 ? ~(value << 1) : value << 1;
  let output = '';
  while (encoded >= 0x20) {
    output += String.fromCharCode((0x20 | (encoded & 0x1f)) + 63);
    encoded >>= 5;
  }
  output += String.fromCharCode(encoded + 63);
  return output;
}

/**
 * Encodes `[GeoPoint]` into a Google Encoded Polyline Algorithm string (precision 5).
 */
export function encodePolyline(points: readonly GeoPoint[]): string {
  if (points.length === 0) return '';

  let prevLat = 0;
  let prevLng = 0;
  let result = '';

  for (const point of points) {
    if (!isValidGeoPoint(point)) continue;
    const latE5 = Math.round(point.lat * 1e5);
    const lngE5 = Math.round(point.lng * 1e5);
    result += encodeSignedValue(latE5 - prevLat);
    result += encodeSignedValue(lngE5 - prevLng);
    prevLat = latE5;
    prevLng = lngE5;
  }

  return result;
}

/**
 * Decodes a Google Encoded Polyline Algorithm string (precision 5) into `[GeoPoint]`.
 */
export function decodePolyline(encoded: string): GeoPoint[] {
  if (!encoded) return [];

  const points: GeoPoint[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;

    do {
      if (index >= encoded.length) return points;
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const deltaLat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += deltaLat;

    shift = 0;
    result = 0;

    do {
      if (index >= encoded.length) return points;
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const deltaLng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += deltaLng;

    const point: GeoPoint = { lat: lat / 1e5, lng: lng / 1e5 };
    if (isValidGeoPoint(point)) {
      points.push(point);
    }
  }

  return points;
}
