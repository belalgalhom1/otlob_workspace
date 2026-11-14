export interface GeoPoint {
  lng: number;
  lat: number;
}

export const EARTH_MEAN_RADIUS_KM = 6371.0088;

/**
 * Great-circle distance in km between two WGS84 points.
 * Matches PostGIS ST_Distance on ::geography closely without DB round-trips.
 */
export function haversineKm(a: GeoPoint, b: GeoPoint): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_MEAN_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
}

/**
 * Quantize coordinates onto a grid of `precisionMeters` for customer-facing
 * privacy. Returns the exact point when `precisionMeters <= 0`.
 */
export function applyPrecisionReduction(
  lng: number,
  lat: number,
  precisionMeters: number,
): GeoPoint {
  if (precisionMeters <= 0) return { lng, lat };
  // 1 degree latitude ≈ 111,111 meters; longitude scales by cos(lat)
  const latDeg = precisionMeters / 111111;
  const lngDeg = precisionMeters / (111111 * Math.cos((lat * Math.PI) / 180));
  return {
    lng: Math.round(lng / lngDeg) * lngDeg,
    lat: Math.round(lat / latDeg) * latDeg,
  };
}
