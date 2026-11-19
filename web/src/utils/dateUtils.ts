/**
 * Date and Time utilities for EDUCCA Cusco
 * Handles conversions between local form inputs and backend RFC 3339 timestamps.
 */

export function getTodayLocalISO(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function formatToRFC3339(fechaProgramada: string, horaInicio: string): string {
  const cleanHora = (horaInicio || '09:00').slice(0, 5);
  const localIso = `${fechaProgramada}T${cleanHora}:00`;
  const date = new Date(localIso);
  if (!isNaN(date.getTime())) {
    return date.toISOString();
  }
  return `${localIso}Z`;
}

export function validateTimeRange(
  horaInicio: string,
  horaFin: string
): { valid: boolean; diffMinutes: number; error?: string } {
  const [h1, m1] = (horaInicio || '').slice(0, 5).split(':').map(Number);
  const [h2, m2] = (horaFin || '').slice(0, 5).split(':').map(Number);
  if (isNaN(h1) || isNaN(m1) || isNaN(h2) || isNaN(m2)) {
    return { valid: false, diffMinutes: 0, error: 'Formato de hora inválido (use HH:mm)' };
  }
  const diff = h2 * 60 + m2 - (h1 * 60 + m1);
  if (diff <= 0) {
    return {
      valid: false,
      diffMinutes: 0,
      error: 'La hora de fin debe ser posterior a la hora de inicio',
    };
  }
  if (diff < 15 || diff > 720) {
    return {
      valid: false,
      diffMinutes: diff,
      error: 'La duración de la sesión debe estar entre 15 minutos y 12 horas',
    };
  }
  return { valid: true, diffMinutes: diff };
}

export function calculateDurationMinutes(horaInicio: string, horaFin: string): number {
  const check = validateTimeRange(horaInicio, horaFin);
  if (check.valid) {
    return check.diffMinutes;
  }
  return 120;
}

export function extractLocalDate(isoString: string): string {
  if (!isoString) return getTodayLocalISO();
  const date = new Date(isoString);
  if (isNaN(date.getTime())) {
    return isoString.slice(0, 10);
  }
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

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

export function extractEndTime(isoString: string, duracionMinutos: number = 120): string {
  if (!isoString) return '11:00';
  const date = new Date(isoString);
  if (isNaN(date.getTime())) {
    return '11:00';
  }
  const endDate = new Date(date.getTime() + (duracionMinutos || 120) * 60000);
  if (isNaN(endDate.getTime())) {
    return '11:00';
  }
  const hours = String(endDate.getHours()).padStart(2, '0');
  const minutes = String(endDate.getMinutes()).padStart(2, '0');
  return `${hours}:${minutes}`;
}
