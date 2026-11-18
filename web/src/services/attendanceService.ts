import {
  AttendanceRecord,
  AttendanceStatus,
  GoAsistencia,
  GoInscripcionSesion,
  GoPersona,
  GoSesion,
} from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { MOCK_ATTENDANCES } from '../data/mock/attendances';

class AttendanceService {
  private mockAttendances: AttendanceRecord[] = [...MOCK_ATTENDANCES];

  async getAttendances(): Promise<AttendanceRecord[]> {
    if (authService.isDemo()) {
      return [...this.mockAttendances];
    }

    // In API mode: fetch sessions and consolidate attendances
    try {
      const sesiones = await apiClient.get<GoSesion[]>('/sesiones');
      if (!sesiones || sesiones.length === 0) return [];

      const records: AttendanceRecord[] = [];
      // Fetch attendances for each session
      for (const sesion of sesiones.slice(0, 10)) {
        const sessionRecords = await this.getAttendancesBySession(sesion.id.toString(), sesion);
        records.push(...sessionRecords);
      }
      return records;
    } catch {
      return [];
    }
  }

  async getAttendancesBySession(sesionId: string, preloadedSesion?: GoSesion): Promise<AttendanceRecord[]> {
    if (authService.isDemo()) {
      return this.mockAttendances.filter(a => a.sesionId === sesionId);
    }

    const numId = parseInt(sesionId.replace('ses-', ''), 10) || sesionId;

    try {
      const [sesion, asistencias, inscripciones] = await Promise.all([
        preloadedSesion || apiClient.get<GoSesion>(`/sesiones/${numId}`),
        apiClient.get<GoAsistencia[]>(`/sesiones/${numId}/asistencias`).catch(() => [] as GoAsistencia[]),
        apiClient.get<GoInscripcionSesion[]>(`/sesiones/${numId}/inscripciones`).catch(() => [] as GoInscripcionSesion[]),
      ]);

      const records: AttendanceRecord[] = [];
      const personasMap = new Map<number, { dni: string; nombre: string; categoria: string }>();

      // Register enrolled persons
      inscripciones.forEach(ins => {
        personasMap.set(ins.persona_id, {
          dni: ins.dni,
          nombre: `${ins.nombres} ${ins.apellidos}`.trim(),
          categoria: ins.categoria || 'PAC',
        });
      });

      // Map attendees
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
            personaInfo = { dni: '00000000', nombre: `Participante #${asis.persona_id}`, categoria: 'PAC' };
          }
        }

        const hora = asis.registrado_at ? new Date(asis.registrado_at).toTimeString().split(' ')[0] : '-';
        const fecha = asis.registrado_at ? asis.registrado_at.slice(0, 10) : sesion.fecha_inicio.slice(0, 10);

        records.push({
          id: `att-${sesion.id}-${asis.persona_id}`,
          sesionId: sesion.id.toString(),
          tallerNombre: sesion.titulo,
          sedeNombre: `Sede #${sesion.organizacion_id || 'Principal'}`,
          participanteId: asis.persona_id.toString(),
          participanteDni: personaInfo.dni,
          participanteNombre: personaInfo.nombre,
          participanteCategoria: personaInfo.categoria,
          horaMarcado: hora,
          fecha,
          estado: 'PRESENTE',
          metodo: asis.metodo_registro === 'QR_GPS' ? 'QR_GPS' : 'MANUAL',
          distanciaMetros: asis.distancia_metros ? Math.round(asis.distancia_metros) : undefined,
          validado: true,
          observaciones: asis.distancia_metros ? `Distancia verificada: ${Math.round(asis.distancia_metros)} m` : 'Registro en sede',
        });
      }

      // Add enrolled persons who haven't checked in yet as PENDIENTE
      for (const ins of inscripciones) {
        if (!attendeePersonaIds.has(ins.persona_id)) {
          records.push({
            id: `ins-${sesion.id}-${ins.persona_id}`,
            sesionId: sesion.id.toString(),
            tallerNombre: sesion.titulo,
            sedeNombre: `Sede #${sesion.organizacion_id || 'Principal'}`,
            participanteId: ins.persona_id.toString(),
            participanteDni: ins.dni,
            participanteNombre: `${ins.nombres} ${ins.apellidos}`.trim(),
            participanteCategoria: ins.categoria || 'PAC',
            horaMarcado: '-',
            fecha: sesion.fecha_inicio.slice(0, 10),
            estado: 'PENDIENTE',
            metodo: 'QR_GPS',
            validado: false,
            observaciones: 'Inscrito, pendiente de marcar asistencia',
          });
        }
      }

      return records;
    } catch {
      return [];
    }
  }

  async updateAttendanceStatus(
    id: string,
    estado: AttendanceStatus,
    observaciones?: string,
    sesionIdContext?: string,
    personaIdContext?: string
  ): Promise<AttendanceRecord | null> {
    if (authService.isDemo()) {
      const record = this.mockAttendances.find(a => a.id === id);
      if (!record) return null;
      record.estado = estado;
      if (observaciones !== undefined) record.observaciones = observaciones;
      if (estado === 'PRESENTE' && record.horaMarcado === '-') {
        record.horaMarcado = new Date().toTimeString().split(' ')[0];
      }
      return { ...record };
    }

    const sesionId = sesionIdContext || (id.includes('-') ? id.split('-')[1] : '1');
    const personaId = personaIdContext || (id.includes('-') ? id.split('-')[2] : '1');
    const numSesionId = parseInt(sesionId, 10);
    const numPersonaId = parseInt(personaId, 10);

    if (estado === 'PRESENTE') {
      // Upsert attendance in Go backend
      await apiClient.post(`/sesiones/${numSesionId}/asistencias`, {
        persona_id: numPersonaId,
        participacion: 'ASISTENTE',
      });
    } else {
      // Revert attendance (delete record)
      await apiClient.delete(`/sesiones/${numSesionId}/asistencias/${numPersonaId}`).catch(() => {});
    }

    const refreshed = await this.getAttendancesBySession(numSesionId.toString());
    return refreshed.find(r => r.participanteId === personaId) || null;
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
      'Estado',
      'Método',
      'Distancia (m)',
      'Observaciones',
    ];

    const rows = records.map(r => [
      r.id,
      `"${r.tallerNombre}"`,
      `"${r.sedeNombre}"`,
      r.fecha,
      r.horaMarcado,
      r.participanteDni,
      `"${r.participanteNombre}"`,
      r.participanteCategoria,
      r.estado,
      r.metodo,
      r.distanciaMetros ?? '',
      `"${r.observaciones ?? ''}"`,
    ]);

    return [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
  }
}

export const attendanceService = new AttendanceService();
