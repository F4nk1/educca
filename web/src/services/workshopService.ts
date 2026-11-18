import {
  Workshop,
  SessionItem,
  SessionStatus,
  GoSesion,
  GoSesionMonitoreo,
  GoMetaAnual,
  GoQRResponse,
} from '../models/types';
import { apiClient } from './apiClient';
import { authService } from './authService';
import { venueService } from './venueService';
import { userService } from './userService';
import {
  formatToRFC3339,
  calculateDurationMinutes,
  extractLocalDate,
  extractLocalTime,
} from '../utils/dateUtils';
import { MOCK_WORKSHOPS, MOCK_SESSIONS } from '../data/mock/workshops';

class WorkshopService {
  private mockWorkshops: Workshop[] = [...MOCK_WORKSHOPS];
  private mockSessions: SessionItem[] = [...MOCK_SESSIONS];

  async getWorkshops(): Promise<Workshop[]> {
    if (authService.isDemo()) {
      return [...this.mockWorkshops];
    }

    const sesiones = await apiClient.get<GoSesion[]>('/sesiones');
    const [venues, users] = await Promise.all([
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);

    const venueMap = new Map(venues.map(v => [v.numericId ?? parseInt(v.id, 10), v.nombre]));
    const userMap = new Map(users.map(u => [parseInt(u.id, 10), `${u.nombres} ${u.apellidos}`]));

    return sesiones.map(s => this.mapGoSesionToWorkshop(s, venueMap, userMap));
  }

  async getWorkshopById(id: string): Promise<Workshop | undefined> {
    if (authService.isDemo()) {
      return this.mockWorkshops.find(w => w.id === id);
    }

    const numId = parseInt(id.replace('ws-', '').replace('ses-', ''), 10) || id;
    const sesion = await apiClient.get<GoSesion>(`/sesiones/${numId}`);
    return this.mapGoSesionToWorkshop(sesion, new Map(), new Map());
  }

  async createWorkshop(data: {
    nombre: string;
    sedeId: string;
    sedeNombre?: string;
    fecha: string;
    horaInicio: string;
    horaFin: string;
    capacitadorId: string;
    capacitadorNombre?: string;
    cuposTotales: number;
    ejeTematico: string;
    descripcion?: string;
    metaAnualId?: number;
  }): Promise<Workshop> {
    if (authService.isDemo()) {
      const newWorkshop: Workshop = {
        id: `ws-${Date.now()}`,
        nombre: data.nombre,
        sedeId: data.sedeId,
        sedeNombre: data.sedeNombre || 'Sede Municipal',
        fecha: data.fecha,
        horaInicio: data.horaInicio,
        horaFin: data.horaFin,
        capacitadorId: data.capacitadorId,
        capacitadorNombre: data.capacitadorNombre || 'Capacitador Responsable',
        cuposTotales: data.cuposTotales,
        cuposDisponibles: data.cuposTotales,
        inscritos: 0,
        estado: 'PROGRAMADO',
        ejeTematico: data.ejeTematico,
        descripcion: data.descripcion || '',
      };
      this.mockWorkshops.unshift(newWorkshop);

      const newSession: SessionItem = {
        id: `ses-${Date.now()}`,
        tallerId: newWorkshop.id,
        tallerNombre: newWorkshop.nombre,
        sedeNombre: newWorkshop.sedeNombre,
        fecha: newWorkshop.fecha,
        hora: `${newWorkshop.horaInicio} - ${newWorkshop.horaFin}`,
        estado: 'PROGRAMADA',
        capacitadorNombre: newWorkshop.capacitadorNombre,
        qrActivo: false,
        totalInscritos: 0,
        totalAsistencias: 0,
      };
      this.mockSessions.unshift(newSession);

      return newWorkshop;
    }

    // Go Backend: Find or fetch active meta anual
    let metaId = data.metaAnualId;
    if (!metaId) {
      try {
        const metas = await this.getMetasAnuales();
        metaId = metas.length > 0 ? metas[0].id : 1;
      } catch {
        metaId = 1;
      }
    }

    // Calculate duration in minutes from horaInicio (HH:mm) to horaFin (HH:mm)
    const duracionMinutos = calculateDurationMinutes(data.horaInicio, data.horaFin);

    // Format fecha_inicio as RFC 3339 for Go time.Time parsing
    const fechaInicioRFC3339 = formatToRFC3339(data.fecha, data.horaInicio);

    // Map eje temático to Go backend valid enum
    const validEje = this.mapToBackendEje(data.ejeTematico);

    const rawOrgId = typeof data.sedeId === 'number'
      ? data.sedeId
      : parseInt(String(data.sedeId).replace('ven-', ''), 10);
    const organizacionId = isNaN(rawOrgId) || rawOrgId <= 0 ? null : rawOrgId;

    const rawRespId = typeof data.capacitadorId === 'number'
      ? data.capacitadorId
      : parseInt(String(data.capacitadorId).replace('usr-', ''), 10);
    const responsableId = isNaN(rawRespId) || rawRespId <= 0 ? 1 : rawRespId;

    const cupos = parseInt(String(data.cuposTotales), 10);
    const cupoMaximo = isNaN(cupos) || cupos <= 0 ? 50 : cupos;

    const payload = {
      meta_anual_id: Number(metaId),
      organizacion_id: organizacionId,
      responsable_id: responsableId,
      titulo: data.nombre.trim(),
      modalidad: 'PRESENCIAL',
      eje_tematico: validEje,
      fecha_inicio: fechaInicioRFC3339,
      duracion_minutos: duracionMinutos,
      cupo_maximo: cupoMaximo,
    };

    const res = await apiClient.post<{ id: number }>('/sesiones', payload);

    return {
      id: res.id.toString(),
      numericId: res.id,
      nombre: data.nombre,
      sedeId: data.sedeId,
      sedeNombre: data.sedeNombre || 'Sede Asignada',
      fecha: data.fecha,
      horaInicio: data.horaInicio,
      horaFin: data.horaFin,
      capacitadorId: data.capacitadorId,
      capacitadorNombre: data.capacitadorNombre || 'Capacitador',
      cuposTotales: data.cuposTotales,
      cuposDisponibles: data.cuposTotales,
      inscritos: 0,
      estado: 'PROGRAMADO',
      ejeTematico: data.ejeTematico,
      descripcion: data.descripcion || '',
    };
  }

  async getSessions(): Promise<SessionItem[]> {
    if (authService.isDemo()) {
      return [...this.mockSessions];
    }

    const sesiones = await apiClient.get<GoSesion[]>('/sesiones');
    const [venues, users] = await Promise.all([
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);

    const venueMap = new Map(venues.map(v => [v.numericId ?? parseInt(v.id, 10), v.nombre]));
    const userMap = new Map(users.map(u => [parseInt(u.id, 10), `${u.nombres} ${u.apellidos}`]));

    return sesiones.map(s => this.mapGoSesionToSessionItem(s, venueMap, userMap));
  }

  async getSessionById(id: string): Promise<SessionItem | undefined> {
    if (authService.isDemo()) {
      return this.mockSessions.find(s => s.id === id);
    }

    const numId = parseInt(id.replace('ses-', ''), 10) || id;
    const sesion = await apiClient.get<GoSesion>(`/sesiones/${numId}`);
    return this.mapGoSesionToSessionItem(sesion, new Map(), new Map());
  }

  async updateSessionStatus(id: string, estado: SessionStatus): Promise<SessionItem | null> {
    if (authService.isDemo()) {
      const session = this.mockSessions.find(s => s.id === id);
      if (!session) return null;
      session.estado = estado;
      if (estado === 'FINALIZADA' || estado === 'CANCELADA') {
        session.qrActivo = false;
      }
      return { ...session };
    }

    const numId = parseInt(id.replace('ses-', ''), 10) || id;

    // Map frontend status to Go backend valid status
    let backendEstado = 'PROGRAMADA';
    if (estado === 'EN_CURSO' || estado === 'EJECUTADA' || estado === 'FINALIZADA') {
      backendEstado = 'EJECUTADA';
    } else if (estado === 'VALIDADA') {
      backendEstado = 'VALIDADA';
    } else if (estado === 'CANCELADA') {
      backendEstado = 'CANCELADA';
    }

    await apiClient.patch(`/sesiones/${numId}/estado`, { estado: backendEstado });
    const updated = await apiClient.get<GoSesion>(`/sesiones/${numId}`);
    return this.mapGoSesionToSessionItem(updated, new Map(), new Map());
  }

  async getMetasAnuales(): Promise<GoMetaAnual[]> {
    if (authService.isDemo()) {
      return [{ id: 1, anio: 2026, actividad_minam: 'PAC', indicador: 'Promotores Capacitados', meta_programada: 500, presupuesto: 15000 }];
    }
    return apiClient.get<GoMetaAnual[]>('/metas-anuales');
  }

  // --- Real Dynamic QR Management ---

  async generateQR(sesionId: string | number, ttlSeconds: number = 300): Promise<GoQRResponse> {
    const numId = typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      return {
        sesion_id: numId || 1,
        qr_token: `EDUCCA-DEMO-QR-${numId}-${Date.now().toString().slice(-4)}`,
        expires_at: new Date(Date.now() + ttlSeconds * 1000).toISOString(),
        segundos_restantes: ttlSeconds,
      };
    }

    return apiClient.post<GoQRResponse>(`/sesiones/${numId}/qr`, { ttl_seconds: ttlSeconds });
  }

  async getActiveQR(sesionId: string | number): Promise<GoQRResponse | null> {
    const numId = typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (ses && ses.qrActivo) {
        return {
          sesion_id: numId,
          qr_token: ses.qrToken || 'EDUCCA-DEMO-QR',
          expires_at: new Date(Date.now() + 240000).toISOString(),
          segundos_restantes: ses.qrSegundosRestantes || 240,
        };
      }
      return null;
    }

    try {
      return await apiClient.get<GoQRResponse>(`/sesiones/${numId}/qr`);
    } catch {
      return null;
    }
  }

  async revokeQR(sesionId: string | number): Promise<boolean> {
    const numId = typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (ses) ses.qrActivo = false;
      return true;
    }

    await apiClient.delete(`/sesiones/${numId}/qr`);
    return true;
  }

  async getMonitoreo(sesionId: string | number): Promise<GoSesionMonitoreo | null> {
    const numId = typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (!ses) return null;
      return {
        sesion: {
          id: numId,
          meta_anual_id: 1,
          responsable_id: 1,
          titulo: ses.tallerNombre,
          modalidad: 'PRESENCIAL',
          eje_tematico: 'SEGREGACION_RECICLA',
          fecha_inicio: new Date().toISOString(),
          duracion_minutos: 120,
          cupo_maximo: 30,
          inscritos_actuales: ses.totalInscritos,
          cupos_disponibles: 10,
          estado: ses.estado,
        },
        qr_activo: ses.qrActivo,
        qr_segundos_restantes: ses.qrSegundosRestantes || 0,
        total_inscritos: ses.totalInscritos,
        total_asistentes: ses.totalAsistencias,
        asistencias: [],
      };
    }

    return apiClient.get<GoSesionMonitoreo>(`/sesiones/${numId}/monitoreo`);
  }

  private mapGoSesionToWorkshop(
    s: GoSesion,
    venueMap: Map<number, string>,
    userMap: Map<number, string>
  ): Workshop {
    const fecha = extractLocalDate(s.fecha_inicio);
    const horaInicio = extractLocalTime(s.fecha_inicio);

    const dateObj = new Date(s.fecha_inicio);
    const finObj = new Date(dateObj.getTime() + (s.duracion_minutos || 120) * 60000);
    const horaFin = extractLocalTime(finObj.toISOString());

    const sedeNombre = s.organizacion_id ? (venueMap.get(s.organizacion_id) || `Sede #${s.organizacion_id}`) : 'Sede no asignada';
    const capacitadorNombre = userMap.get(s.responsable_id) || `Capacitador #${s.responsable_id}`;

    return {
      id: s.id.toString(),
      numericId: s.id,
      nombre: s.titulo,
      sedeId: s.organizacion_id ? s.organizacion_id.toString() : '',
      sedeNombre,
      fecha,
      horaInicio,
      horaFin,
      capacitadorId: s.responsable_id.toString(),
      capacitadorNombre,
      cuposTotales: s.cupo_maximo || 30,
      cuposDisponibles: s.cupos_disponibles ?? 30,
      inscritos: s.inscritos_actuales ?? 0,
      estado: (s.estado === 'EJECUTADA' ? 'EN_CURSO' : s.estado) as any,
      ejeTematico: this.friendlyEjeName(s.eje_tematico),
      descripcion: `Sesión ${s.modalidad} registrada en Programa EDUCCA Cusco.`,
      metaAnualId: s.meta_anual_id,
    };
  }

  private mapGoSesionToSessionItem(
    s: GoSesion,
    venueMap: Map<number, string>,
    userMap: Map<number, string>
  ): SessionItem {
    const fecha = extractLocalDate(s.fecha_inicio);
    const horaInicio = extractLocalTime(s.fecha_inicio);

    const dateObj = new Date(s.fecha_inicio);
    const finObj = new Date(dateObj.getTime() + (s.duracion_minutos || 120) * 60000);
    const horaFin = extractLocalTime(finObj.toISOString());

    const sedeNombre = s.organizacion_id ? (venueMap.get(s.organizacion_id) || `Sede #${s.organizacion_id}`) : 'Sede General';
    const capacitadorNombre = userMap.get(s.responsable_id) || `Capacitador #${s.responsable_id}`;

    return {
      id: s.id.toString(),
      numericId: s.id,
      tallerId: s.id.toString(),
      tallerNombre: s.titulo,
      sedeNombre,
      fecha,
      hora: `${horaInicio} - ${horaFin}`,
      estado: (s.estado === 'EJECUTADA' ? 'EN_CURSO' : s.estado) as any,
      capacitadorNombre,
      qrActivo: false,
      totalInscritos: s.inscritos_actuales ?? 0,
      totalAsistencias: 0,
    };
  }

  private mapToBackendEje(eje: string): string {
    const upper = eje.toUpperCase();
    if (upper.includes('COMPOST')) return 'COMPOSTAJE';
    if (upper.includes('RECICLAJE_FORMAL') || upper.includes('CIRCULAR')) return 'RECICLAJE_FORMAL';
    if (upper.includes('ECOEFICIENCIA') || upper.includes('AGUA') || upper.includes('HIDRICA')) return 'ECOEFICIENCIA';
    if (upper.includes('GESTION_RESIDUOS') || upper.includes('INTEGRAL')) return 'GESTION_RESIDUOS';
    return 'SEGREGACION_RECICLA';
  }

  private friendlyEjeName(eje: string): string {
    switch (eje) {
      case 'COMPOSTAJE':
        return 'Compostaje y Valorización Orgánica';
      case 'RECICLAJE_FORMAL':
        return 'Economía Circular y Reciclaje Inclusivo';
      case 'ECOEFICIENCIA':
        return 'Ecoeficiencia y Recursos Hídricos';
      case 'GESTION_RESIDUOS':
        return 'Gestión Integral de Residuos Sólidos';
      default:
        return 'Segregación en la Fuente y Reciclaje';
    }
  }
}

export const workshopService = new WorkshopService();
