import {
  Workshop,
  SessionItem,
  SessionStatus,
  SessionModalidad,
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
  extractEndTime,
} from '../utils/dateUtils';
import { MOCK_WORKSHOPS, MOCK_SESSIONS } from '../data/mock/workshops';

class WorkshopService {
  private mockWorkshops: Workshop[] = [...MOCK_WORKSHOPS];
  private mockSessions: SessionItem[] = [...MOCK_SESSIONS];
  private mockMetas: GoMetaAnual[] = [
    {
      id: 1,
      anio: 2026,
      actividad_minam: 'PAC',
      indicador: 'Promotores Ambientales Comunitarios capacitados',
      meta_programada: 500,
      presupuesto: 15000,
    },
    {
      id: 2,
      anio: 2026,
      actividad_minam: 'PAJ',
      indicador: 'Promotores Ambientales Juveniles acreditados',
      meta_programada: 300,
      presupuesto: 12000,
    },
  ];

  private buildLookups(
    venues: Array<{ id: string; numericId?: number; nombre: string }>,
    users: Array<{ id: string; nombres: string; apellidos: string }>
  ) {
    const venueMap = new Map<number, string>();
    venues.forEach(v => {
      const idNum = v.numericId ?? parseInt(v.id.replace('ven-', ''), 10);
      if (!isNaN(idNum)) {
        venueMap.set(idNum, v.nombre);
      }
    });

    const userMap = new Map<number, string>();
    users.forEach(u => {
      const idNum = parseInt(u.id.replace('usr-', ''), 10);
      if (!isNaN(idNum)) {
        userMap.set(idNum, `${u.nombres} ${u.apellidos}`.trim());
      }
    });

    const currentUser = authService.getCurrentUser();
    if (currentUser) {
      const currId = parseInt(currentUser.id.replace('usr-', ''), 10);
      if (!isNaN(currId) && !userMap.has(currId)) {
        userMap.set(currId, `${currentUser.nombres} ${currentUser.apellidos}`.trim());
      }
    }

    return { venueMap, userMap };
  }

  async getWorkshops(): Promise<Workshop[]> {
    if (authService.isDemo()) {
      return [...this.mockWorkshops];
    }

    const sesiones = await apiClient.get<GoSesion[]>('/sesiones');
    const [venues, users] = await Promise.all([
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);

    const { venueMap, userMap } = this.buildLookups(venues, users);
    return sesiones.map(s => this.mapGoSesionToWorkshop(s, venueMap, userMap));
  }

  async getWorkshopById(id: string): Promise<Workshop | undefined> {
    if (authService.isDemo()) {
      return this.mockWorkshops.find(w => w.id === id);
    }

    const numId = parseInt(id.replace('ws-', '').replace('ses-', ''), 10) || id;
    const [sesion, venues, users] = await Promise.all([
      apiClient.get<GoSesion>(`/sesiones/${numId}`),
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);
    const { venueMap, userMap } = this.buildLookups(venues, users);
    return this.mapGoSesionToWorkshop(sesion, venueMap, userMap);
  }

  async createWorkshop(data: {
    nombre: string;
    sedeId: string;
    sedeNombre?: string;
    fecha: string;
    horaInicio: string;
    horaFin: string;
    modalidad?: SessionModalidad;
    capacitadorId: string;
    capacitadorNombre?: string;
    cuposTotales: number;
    ejeTematico: string;
    metaAnualId?: number;
  }): Promise<Workshop> {
    const modalidad: SessionModalidad = data.modalidad || 'PRESENCIAL';
    const duracionMinutos = calculateDurationMinutes(data.horaInicio, data.horaFin);
    const validEje = this.mapToBackendEje(data.ejeTematico);

    if (authService.isDemo()) {
      const nowId = Date.now();
      const newWorkshop: Workshop = {
        id: `ws-${nowId}`,
        numericId: nowId,
        nombre: data.nombre.trim(),
        sedeId: data.sedeId,
        sedeNombre: data.sedeNombre || 'Sede Municipal',
        fecha: data.fecha,
        horaInicio: data.horaInicio,
        horaFin: data.horaFin,
        duracionMinutos,
        modalidad,
        capacitadorId: data.capacitadorId,
        capacitadorNombre: data.capacitadorNombre || 'Capacitador Responsable',
        cuposTotales: data.cuposTotales,
        cuposDisponibles: data.cuposTotales,
        inscritos: 0,
        estado: 'PROGRAMADA',
        ejeTematico: this.friendlyEjeName(validEje),
        ejeTematicoCodigo: validEje,
        descripcion: `Sesión ${modalidad} registrada en Programa EDUCCA Cusco.`,
        metaAnualId: data.metaAnualId || 1,
      };
      this.mockWorkshops.unshift(newWorkshop);

      const newSession: SessionItem = {
        id: `ses-${nowId}`,
        numericId: nowId,
        tallerId: newWorkshop.id,
        tallerNombre: newWorkshop.nombre,
        sedeId: newWorkshop.sedeId,
        sedeNombre: newWorkshop.sedeNombre,
        fecha: newWorkshop.fecha,
        hora: `${newWorkshop.horaInicio} - ${newWorkshop.horaFin}`,
        modalidad,
        estado: 'PROGRAMADA',
        capacitadorId: newWorkshop.capacitadorId,
        capacitadorNombre: newWorkshop.capacitadorNombre,
        qrActivo: false,
        totalInscritos: 0,
        totalAsistencias: 0,
      };
      this.mockSessions.unshift(newSession);

      return newWorkshop;
    }

    let metaId = data.metaAnualId;
    if (!metaId) {
      const metas = await this.getMetasAnuales().catch(() => [] as GoMetaAnual[]);
      if (metas.length > 0) {
        metaId = metas[0].id;
      } else {
        const createdMeta = await this.createMetaAnual({
          anio: new Date().getFullYear(),
          actividad_minam: 'PAC',
          indicador: 'Ciudadanos y promotores ambientales capacitados',
          meta_programada: 500,
          presupuesto: 15000,
        });
        metaId = createdMeta.id;
      }
    }

    const fechaInicioRFC3339 = formatToRFC3339(data.fecha, data.horaInicio);

    const rawOrgId =
      typeof data.sedeId === 'number'
        ? data.sedeId
        : parseInt(String(data.sedeId).replace('ven-', ''), 10);
    const organizacionId = isNaN(rawOrgId) || rawOrgId <= 0 ? null : rawOrgId;

    const rawRespId =
      typeof data.capacitadorId === 'number'
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
      modalidad,
      eje_tematico: validEje,
      fecha_inicio: fechaInicioRFC3339,
      duracion_minutos: duracionMinutos,
      cupo_maximo: cupoMaximo,
    };

    const res = await apiClient.post<{ id: number }>('/sesiones', payload);

    return {
      id: res.id.toString(),
      numericId: res.id,
      nombre: payload.titulo,
      sedeId: data.sedeId,
      sedeNombre: data.sedeNombre || 'Sede Asignada',
      fecha: data.fecha,
      horaInicio: data.horaInicio,
      horaFin: data.horaFin,
      duracionMinutos,
      modalidad,
      capacitadorId: data.capacitadorId,
      capacitadorNombre: data.capacitadorNombre || 'Capacitador',
      cuposTotales: cupoMaximo,
      cuposDisponibles: cupoMaximo,
      inscritos: 0,
      estado: 'PROGRAMADA',
      ejeTematico: this.friendlyEjeName(validEje),
      ejeTematicoCodigo: validEje,
      descripcion: `Sesión ${modalidad} registrada en Programa EDUCCA Cusco.`,
      metaAnualId: Number(metaId),
    };
  }

  async updateWorkshop(
    id: string,
    data: {
      nombre: string;
      sedeId: string;
      fecha: string;
      horaInicio: string;
      horaFin: string;
      modalidad: SessionModalidad;
      capacitadorId: string;
      cuposTotales: number;
      ejeTematico: string;
      metaAnualId: number;
    }
  ): Promise<void> {
    const duracionMinutos = calculateDurationMinutes(data.horaInicio, data.horaFin);
    const validEje = this.mapToBackendEje(data.ejeTematico);

    if (authService.isDemo()) {
      const idx = this.mockWorkshops.findIndex(w => w.id === id);
      if (idx !== -1) {
        this.mockWorkshops[idx] = {
          ...this.mockWorkshops[idx],
          nombre: data.nombre.trim(),
          sedeId: data.sedeId,
          fecha: data.fecha,
          horaInicio: data.horaInicio,
          horaFin: data.horaFin,
          duracionMinutos,
          modalidad: data.modalidad,
          capacitadorId: data.capacitadorId,
          cuposTotales: data.cuposTotales,
          ejeTematico: this.friendlyEjeName(validEje),
          ejeTematicoCodigo: validEje,
          metaAnualId: data.metaAnualId,
        };
      }
      return;
    }

    const numId = parseInt(id.replace('ws-', '').replace('ses-', ''), 10) || id;
    const rawOrgId = parseInt(String(data.sedeId).replace('ven-', ''), 10);
    const organizacionId = isNaN(rawOrgId) || rawOrgId <= 0 ? null : rawOrgId;
    const rawRespId = parseInt(String(data.capacitadorId).replace('usr-', ''), 10);
    const responsableId = isNaN(rawRespId) || rawRespId <= 0 ? 1 : rawRespId;

    await apiClient.put(`/sesiones/${numId}`, {
      meta_anual_id: Number(data.metaAnualId || 1),
      organizacion_id: organizacionId,
      responsable_id: responsableId,
      titulo: data.nombre.trim(),
      modalidad: data.modalidad || 'PRESENCIAL',
      eje_tematico: validEje,
      fecha_inicio: formatToRFC3339(data.fecha, data.horaInicio),
      duracion_minutos: duracionMinutos,
      cupo_maximo: data.cuposTotales,
    });
  }

  async deleteWorkshop(id: string): Promise<void> {
    if (authService.isDemo()) {
      this.mockWorkshops = this.mockWorkshops.filter(w => w.id !== id);
      this.mockSessions = this.mockSessions.filter(s => s.id !== id && s.tallerId !== id);
      return;
    }

    const numId = parseInt(id.replace('ws-', '').replace('ses-', ''), 10) || id;
    await apiClient.delete(`/sesiones/${numId}`);
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

    const { venueMap, userMap } = this.buildLookups(venues, users);
    return sesiones.map(s => this.mapGoSesionToSessionItem(s, venueMap, userMap));
  }

  async getSessionById(id: string): Promise<SessionItem | undefined> {
    if (authService.isDemo()) {
      return this.mockSessions.find(s => s.id === id);
    }

    const numId = parseInt(id.replace('ses-', ''), 10) || id;
    const [sesion, venues, users] = await Promise.all([
      apiClient.get<GoSesion>(`/sesiones/${numId}`),
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);
    const { venueMap, userMap } = this.buildLookups(venues, users);
    return this.mapGoSesionToSessionItem(sesion, venueMap, userMap);
  }

  async updateSessionStatus(id: string, estado: SessionStatus): Promise<SessionItem | null> {
    if (authService.isDemo()) {
      const session = this.mockSessions.find(s => s.id === id);
      if (!session) return null;
      session.estado = estado;
      if (estado === 'VALIDADA' || estado === 'CANCELADA') {
        session.qrActivo = false;
      }
      const ws = this.mockWorkshops.find(w => w.id === session.tallerId || w.id === id);
      if (ws) {
        ws.estado = estado;
      }
      return { ...session };
    }

    const numId = parseInt(id.replace('ses-', '').replace('ws-', ''), 10) || id;

    await apiClient.patch(`/sesiones/${numId}/estado`, { estado });
    const [updated, venues, users] = await Promise.all([
      apiClient.get<GoSesion>(`/sesiones/${numId}`),
      venueService.getVenues().catch(() => []),
      userService.getUsers().catch(() => []),
    ]);
    const { venueMap, userMap } = this.buildLookups(venues, users);
    return this.mapGoSesionToSessionItem(updated, venueMap, userMap);
  }

  async getMetasAnuales(): Promise<GoMetaAnual[]> {
    if (authService.isDemo()) {
      return [...this.mockMetas];
    }
    return apiClient.get<GoMetaAnual[]>('/metas-anuales');
  }

  async createMetaAnual(meta: Omit<GoMetaAnual, 'id'>): Promise<GoMetaAnual> {
    if (authService.isDemo()) {
      const created: GoMetaAnual = { ...meta, id: Date.now() };
      this.mockMetas.unshift(created);
      return created;
    }
    const res = await apiClient.post<{ id: number }>('/metas-anuales', meta);
    return { ...meta, id: res.id };
  }

  // --- Real Dynamic QR Management ---

  async generateQR(sesionId: string | number, ttlSeconds: number = 300): Promise<GoQRResponse> {
    const numId =
      typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const token = `EDUCCA-DEMO-QR-${numId}-${Date.now().toString().slice(-4)}`;
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (ses) {
        ses.qrActivo = true;
        ses.qrToken = token;
        ses.qrSegundosRestantes = ttlSeconds;
      }
      return {
        sesion_id: numId || 1,
        qr_token: token,
        expires_at: new Date(Date.now() + ttlSeconds * 1000).toISOString(),
        segundos_restantes: ttlSeconds,
      };
    }

    return apiClient.post<GoQRResponse>(`/sesiones/${numId}/qr`, { ttl_seconds: ttlSeconds });
  }

  async getActiveQR(sesionId: string | number): Promise<GoQRResponse | null> {
    const numId =
      typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

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
    const numId =
      typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (ses) ses.qrActivo = false;
      return true;
    }

    await apiClient.delete(`/sesiones/${numId}/qr`);
    return true;
  }

  async getMonitoreo(sesionId: string | number): Promise<GoSesionMonitoreo | null> {
    const numId =
      typeof sesionId === 'string' ? parseInt(sesionId.replace('ses-', ''), 10) : sesionId;

    if (authService.isDemo()) {
      const ses = this.mockSessions.find(s => s.id === `ses-${numId}` || s.id === numId.toString());
      if (!ses) return null;
      return {
        sesion: {
          id: numId,
          meta_anual_id: 1,
          responsable_id: 2,
          titulo: ses.tallerNombre,
          modalidad: ses.modalidad || 'PRESENCIAL',
          eje_tematico: 'SEGREGACION_RECICLA',
          fecha_inicio: new Date().toISOString(),
          duracion_minutos: 120,
          cupo_maximo: 30,
          inscritos_actuales: ses.totalInscritos,
          cupos_disponibles: Math.max(30 - ses.totalInscritos, 0),
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

  private normalizeSessionStatus(raw: string): SessionStatus {
    const upper = (raw || '').toUpperCase();
    if (upper === 'EJECUTADA' || upper === 'EN_CURSO') return 'EJECUTADA';
    if (upper === 'VALIDADA' || upper === 'FINALIZADA' || upper === 'FINALIZADO') return 'VALIDADA';
    if (upper === 'CANCELADA' || upper === 'CANCELADO') return 'CANCELADA';
    return 'PROGRAMADA';
  }

  private mapGoSesionToWorkshop(
    s: GoSesion,
    venueMap: Map<number, string>,
    userMap: Map<number, string>
  ): Workshop {
    const fecha = extractLocalDate(s.fecha_inicio);
    const horaInicio = extractLocalTime(s.fecha_inicio);
    const horaFin = extractEndTime(s.fecha_inicio, s.duracion_minutos || 120);

    const sedeNombre = s.organizacion_id
      ? venueMap.get(s.organizacion_id) || `Sede #${s.organizacion_id}`
      : 'Sede no asignada';
    const capacitadorNombre =
      userMap.get(s.responsable_id) || `Capacitador #${s.responsable_id}`;
    const modalidad: SessionModalidad = s.modalidad === 'VIRTUAL' ? 'VIRTUAL' : 'PRESENCIAL';

    return {
      id: s.id.toString(),
      numericId: s.id,
      nombre: s.titulo,
      sedeId: s.organizacion_id ? s.organizacion_id.toString() : '',
      sedeNombre,
      fecha,
      horaInicio,
      horaFin,
      duracionMinutos: s.duracion_minutos || 120,
      modalidad,
      capacitadorId: s.responsable_id.toString(),
      capacitadorNombre,
      cuposTotales: s.cupo_maximo || 30,
      cuposDisponibles: s.cupos_disponibles ?? 30,
      inscritos: s.inscritos_actuales ?? 0,
      estado: this.normalizeSessionStatus(s.estado),
      ejeTematico: this.friendlyEjeName(s.eje_tematico),
      ejeTematicoCodigo: s.eje_tematico || 'SEGREGACION_RECICLA',
      descripcion: `Sesión ${modalidad} registrada en Programa EDUCCA Cusco.`,
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
    const horaFin = extractEndTime(s.fecha_inicio, s.duracion_minutos || 120);

    const sedeNombre = s.organizacion_id
      ? venueMap.get(s.organizacion_id) || `Sede #${s.organizacion_id}`
      : 'Sede General';
    const capacitadorNombre =
      userMap.get(s.responsable_id) || `Capacitador #${s.responsable_id}`;
    const modalidad: SessionModalidad = s.modalidad === 'VIRTUAL' ? 'VIRTUAL' : 'PRESENCIAL';

    return {
      id: s.id.toString(),
      numericId: s.id,
      tallerId: s.id.toString(),
      tallerNombre: s.titulo,
      sedeId: s.organizacion_id ? s.organizacion_id.toString() : undefined,
      sedeNombre,
      fecha,
      hora: `${horaInicio} - ${horaFin}`,
      modalidad,
      estado: this.normalizeSessionStatus(s.estado),
      capacitadorId: s.responsable_id.toString(),
      capacitadorNombre,
      qrActivo: false,
      totalInscritos: s.inscritos_actuales ?? 0,
      totalAsistencias: 0,
    };
  }

  private mapToBackendEje(eje: string): string {
    const upper = (eje || '').toUpperCase();
    if (upper.includes('COMPOST')) return 'COMPOSTAJE';
    if (upper.includes('RECICLAJE_FORMAL') || upper.includes('CIRCULAR')) return 'RECICLAJE_FORMAL';
    if (upper.includes('ECOEFICIENCIA') || upper.includes('AGUA') || upper.includes('HIDRICA'))
      return 'ECOEFICIENCIA';
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
