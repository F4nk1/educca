import {
  AttendanceRecord,
  AttendanceStatus,
  AttendanceParticipation,
  GoAsistencia,
  GoInscripcionSesion,
  GoPersona,
  GoSesion,
} from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { venueService } from './venueService';
import { userService } from './userService';
import { extractLocalDate } from '../utils/dateUtils';
import { MOCK_ATTENDANCES } from '../data/mock/attendances';

interface PersonaLookupInfo {
  dni: string;
  nombre: string;
  categoria: string;
}

class AttendanceService {
  private mockAttendances: AttendanceRecord[] = [...MOCK_ATTENDANCES];

  private async loadSharedCatalogs(): Promise<{
    venueMap: Map<number, string>;
    personaMap: Map<number, PersonaLookupInfo>;
  }> {
    const [venues, users] = await Promise.all([
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);

    const venueMap = new Map<number, string>();
    venues.forEach(v => {
      const numId = v.numericId ?? parseInt(v.id.replace('ven-', ''), 10);
      if (!isNaN(numId)) {
        venueMap.set(numId, v.nombre);
      }
    });

    const personaMap = new Map<number, PersonaLookupInfo>();
    users.forEach(u => {
      const numId = parseInt(u.id.replace('usr-', ''), 10);
      if (!isNaN(numId)) {
        personaMap.set(numId, {
          dni: u.dni,
          nombre: `${u.nombres} ${u.apellidos}`.trim(),
          categoria: u.categoria || 'PAC',
        });
      }
    });

    return { venueMap, personaMap };
  }

  async getAttendances(): Promise<AttendanceRecord[]> {
    if (authService.isDemo()) {
      return [...this.mockAttendances];
    }

    const [sesiones, catalogs] = await Promise.all([
      apiClient.get<GoSesion[]>('/sesiones'),
      this.loadSharedCatalogs(),
    ]);

    if (!sesiones || sesiones.length === 0) return [];

    const perSessionLists = await Promise.all(
      sesiones.map(sesion =>
        this.getAttendancesBySession(sesion.id.toString(), sesion, catalogs).catch(() => [])
      )
    );

    return perSessionLists.flat();
  }

  async getAttendancesBySession(
    sesionId: string,
    preloadedSesion?: GoSesion,
    preloadedCatalogs?: {
      venueMap: Map<number, string>;
      personaMap: Map<number, PersonaLookupInfo>;
    }
  ): Promise<AttendanceRecord[]> {
    if (authService.isDemo()) {
      return this.mockAttendances.filter(
        a => a.sesionId === sesionId || a.sesionId === `ses-${sesionId}`
      );
    }

    const numId = parseInt(sesionId.replace('ses-', '').replace('ws-', ''), 10) || sesionId;

    const [sesion, asistencias, inscripciones, catalogs] = await Promise.all([
      preloadedSesion
        ? Promise.resolve(preloadedSesion)
        : apiClient.get<GoSesion>(`/sesiones/${numId}`),
      apiClient.get<GoAsistencia[]>(`/sesiones/${numId}/asistencias`).catch(() => [] as GoAsistencia[]),
      apiClient
        .get<GoInscripcionSesion[]>(`/sesiones/${numId}/inscripciones`)
        .catch(() => [] as GoInscripcionSesion[]),
      preloadedCatalogs ? Promise.resolve(preloadedCatalogs) : this.loadSharedCatalogs(),
    ]);

    const { venueMap, personaMap } = catalogs;
    const sedeNombre = sesion.organizacion_id
      ? venueMap.get(sesion.organizacion_id) || `Sede #${sesion.organizacion_id}`
      : 'Sede Municipal';

    const records: AttendanceRecord[] = [];
    const personasMap = new Map<number, PersonaLookupInfo>(personaMap);

    inscripciones.forEach(ins => {
      personasMap.set(ins.persona_id, {
        dni: ins.dni,
        nombre: `${ins.nombres} ${ins.apellidos}`.trim(),
        categoria: ins.categoria || 'PAC',
      });
    });

    const attendeePersonaIds = new Set<number>();
    for (const asis of asistencias) {
      attendeePersonaIds.add(asis.persona_id);
      let personaInfo = personasMap.get(asis.persona_id);
      if (!personaInfo) {
        try {
          const p = await apiClient.get<GoPersona>(`/personas/${asis.persona_id}`);
          personaInfo = {
            dni: p.dni,
            nombre: `${p.nombres} ${p.apellidos}`.trim(),
            categoria: p.categoria || 'PAC',
          };
          personasMap.set(asis.persona_id, personaInfo);
        } catch {
          personaInfo = {
            dni: '00000000',
            nombre: `Participante #${asis.persona_id}`,
            categoria: 'PAC',
          };
        }
      }

      const hora = asis.registrado_at
        ? new Date(asis.registrado_at).toTimeString().split(' ')[0]
        : '-';
      const fecha = asis.registrado_at
        ? extractLocalDate(asis.registrado_at)
        : extractLocalDate(sesion.fecha_inicio);

      const participacion: AttendanceParticipation =
        asis.participacion === 'VOLUNTARIO_REPLICA' || asis.participacion === 'PONENTE'
          ? asis.participacion
          : 'ASISTENTE';

      records.push({
        id: `att-${sesion.id}-${asis.persona_id}`,
        sesionId: sesion.id.toString(),
        tallerNombre: sesion.titulo,
        sedeNombre,
        participanteId: asis.persona_id.toString(),
        participanteDni: personaInfo.dni,
        participanteNombre: personaInfo.nombre,
        participanteCategoria: personaInfo.categoria,
        participacion,
        calificacion: asis.calificacion,
        horaMarcado: hora,
        fecha,
        estado: 'PRESENTE',
        metodo: asis.metodo_registro === 'QR_GPS' ? 'QR_GPS' : 'MANUAL',
        distanciaMetros:
          asis.distancia_metros !== undefined ? Math.round(asis.distancia_metros) : undefined,
        validado: true,
        observaciones:
          asis.distancia_metros !== undefined
            ? `Distancia verificada: ${Math.round(asis.distancia_metros)} m`
            : 'Registro manual en sede',
      });
    }

    for (const ins of inscripciones) {
      if (ins.estado === 'CANCELADO') continue;
      if (!attendeePersonaIds.has(ins.persona_id)) {
        records.push({
          id: `ins-${sesion.id}-${ins.persona_id}`,
          sesionId: sesion.id.toString(),
          tallerNombre: sesion.titulo,
          sedeNombre,
          participanteId: ins.persona_id.toString(),
          participanteDni: ins.dni,
          participanteNombre: `${ins.nombres} ${ins.apellidos}`.trim(),
          participanteCategoria: ins.categoria || 'PAC',
          participacion: 'ASISTENTE',
          horaMarcado: '-',
          fecha: extractLocalDate(sesion.fecha_inicio),
          estado: 'PENDIENTE',
          metodo: 'QR_GPS',
          validado: false,
          observaciones: 'Inscrito, pendiente de marcar asistencia',
        });
      }
    }

    return records;
  }

  async updateAttendanceStatus(
    id: string,
    estado: AttendanceStatus,
    observaciones?: string,
    sesionIdContext?: string,
    personaIdContext?: string,
    options?: {
      participacion?: AttendanceParticipation;
      calificacion?: number;
    }
  ): Promise<AttendanceRecord | null> {
    if (authService.isDemo()) {
      const record = this.mockAttendances.find(a => a.id === id);
      if (!record) return null;
      record.estado = estado;
      if (observaciones !== undefined) record.observaciones = observaciones;
      if (options?.participacion) record.participacion = options.participacion;
      if (options?.calificacion !== undefined) record.calificacion = options.calificacion;
      if (estado === 'PRESENTE' && record.horaMarcado === '-') {
        record.horaMarcado = new Date().toTimeString().split(' ')[0];
        record.metodo = 'MANUAL';
        record.validado = true;
      } else if (estado === 'PENDIENTE') {
        record.horaMarcado = '-';
        record.validado = false;
      }
      return { ...record };
    }

    const parts = id.split('-');
    const sesionIdRaw = sesionIdContext || (parts.length >= 2 ? parts[1] : '1');
    const personaIdRaw = personaIdContext || (parts.length >= 3 ? parts[2] : '1');
    const numSesionId = parseInt(sesionIdRaw.replace('ses-', ''), 10);
    const numPersonaId = parseInt(personaIdRaw.replace('usr-', ''), 10);

    if (isNaN(numSesionId) || isNaN(numPersonaId)) {
      throw new Error('Identificador de sesión o participante inválido');
    }

    if (estado === 'PRESENTE') {
      const payload: {
        persona_id: number;
        participacion: AttendanceParticipation;
        calificacion?: number;
      } = {
        persona_id: numPersonaId,
        participacion: options?.participacion || 'ASISTENTE',
      };
      if (
        options?.calificacion !== undefined &&
        !isNaN(options.calificacion) &&
        options.calificacion >= 0 &&
        options.calificacion <= 20
      ) {
        payload.calificacion = options.calificacion;
      }
      await apiClient.post(`/sesiones/${numSesionId}/asistencias`, payload);
    } else {
      await apiClient.delete(`/sesiones/${numSesionId}/asistencias/${numPersonaId}`);
    }

    const refreshed = await this.getAttendancesBySession(numSesionId.toString());
    return refreshed.find(r => r.participanteId === numPersonaId.toString()) || null;
  }

  private escapeCSVField(raw: unknown): string {
    const str = String(raw ?? '');
    // Prevent CSV Formula Injection in spreadsheet apps
    const safeFormula = /^[=+\-@\t\r]/.test(str) ? `'${str}` : str;
    const escapedQuotes = safeFormula.replace(/"/g, '""');
    return `"${escapedQuotes}"`;
  }

  exportToCSV(records: AttendanceRecord[]): string {
    const headers = [
      'ID',
      'Taller',
      'Sede',
      'Fecha',
      'Hora Marcado',
      'DNI',
      'Participante',
      'Categoría',
      'Participación',
      'Calificación',
      'Estado',
      'Método',
      'Distancia (m)',
      'Observaciones',
    ];

    const rows = records.map(r => [
      this.escapeCSVField(r.id),
      this.escapeCSVField(r.tallerNombre),
      this.escapeCSVField(r.sedeNombre),
      this.escapeCSVField(r.fecha),
      this.escapeCSVField(r.horaMarcado),
      this.escapeCSVField(r.participanteDni),
      this.escapeCSVField(r.participanteNombre),
      this.escapeCSVField(r.participanteCategoria),
      this.escapeCSVField(r.participacion || 'ASISTENTE'),
      r.calificacion !== undefined ? this.escapeCSVField(r.calificacion) : '""',
      this.escapeCSVField(r.estado),
      this.escapeCSVField(r.metodo),
      r.distanciaMetros !== undefined ? this.escapeCSVField(r.distanciaMetros) : '""',
      this.escapeCSVField(r.observaciones ?? ''),
    ]);

    return [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
  }
}

export const attendanceService = new AttendanceService();
