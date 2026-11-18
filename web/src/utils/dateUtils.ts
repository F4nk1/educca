/**
 * Date and Time utilities for EDUCCA Cusco
 * Handles conversions between local form inputs and backend RFC 3339 timestamps.
 */

/**
 * Converts a local date ("YYYY-MM-DD") and local time ("HH:mm") into an RFC 3339 ISO string.
 * Example: ("2026-11-28", "09:00") -> "2026-11-28T14:00:00.000Z" (when in America/Lima UTC-5)
 *
 * Preserves the exact user-selected moment and formats it for Go's time.Time parser.
 */
export function formatToRFC3339(fechaProgramada: string, horaInicio: string): string {
  const cleanHora = (horaInicio || '09:00').slice(0, 5);
  const localIso = `${fechaProgramada}T${cleanHora}:00`;
  const date = new Date(localIso);
  if (!isNaN(date.getTime())) {
    return date.toISOString();
  }
  return `${localIso}Z`;
}

/**
 * Calculates duration in minutes between two time strings ("HH:mm").
 * Ensures the duration is positive and within valid signed 16-bit integer bounds (15 to 720 minutes).
 */
export function calculateDurationMinutes(horaInicio: string, horaFin: string): number {
  try {
    const [h1, m1] = (horaInicio || '09:00').slice(0, 5).split(':').map(Number);
    const [h2, m2] = (horaFin || '11:00').slice(0, 5).split(':').map(Number);
    const diff = (h2 * 60 + m2) - (h1 * 60 + m1);
    if (diff > 0) {
      return Math.min(Math.max(diff, 15), 720);
    }
  } catch {
    // ignore parsing errors
  }
  return 120;
}

/**
 * Extracts the local date ("YYYY-MM-DD") from an ISO / RFC 3339 timestamp,
 * avoiding accidental date displacement caused by UTC day boundaries.
 */
export function extractLocalDate(isoString: string): string {
  if (!isoString) return '';
  const date = new Date(isoString);
  if (isNaN(date.getTime())) {
    return isoString.slice(0, 10);
  }
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Extracts the local time ("HH:mm") from an ISO / RFC 3339 timestamp.
 */
export function extractLocalTime(isoString: string): string {
  if (!isoString) return '09:00';
  const date = new Date(isoString);
  if (isNaN(date.getTime())) {
    return '09:00';
  }
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}
