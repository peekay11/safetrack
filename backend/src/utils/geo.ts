// Calculate distance between two coordinates using the Haversine formula in meters
export function haversineDistanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371e3; // Earth's radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const deltaPhi = ((lat2 - lat1) * Math.PI) / 180;
  const deltaLambda = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

// Distance in kilometers
export function haversineDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  return haversineDistanceMeters(lat1, lon1, lat2, lon2) / 1000;
}

// Check proximity rule: e.g. within 100m to 500m
export function isWithinProximity(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
  maxMeters = 500
): boolean {
  const distance = haversineDistanceMeters(lat1, lon1, lat2, lon2);
  return distance <= maxMeters;
}
