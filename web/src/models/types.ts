export type UserRole = 'admin' | 'coordinador' | 'capacitador' | 'capacitando' | 'consulta' | 'promotor';

export type PromoterCategory = 'PAC' | 'PAJ' | 'COMERCIANTE' | 'RECICLADOR';

// --- Go Backend REST DTOs ---

export interface GoToken {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

export interface GoRol {
  id: number;
  nombre: string;
  descripcion: string;
}

export interface GoPersona {
  id: number;
  dni: string;
  nombres: string;
  apellidos: string;
  sexo: string;
  fecha_nacimiento: string;
  telefono?: string;
  email?: string;
  categoria?: string;
  consentimiento_at?: string;
  consentimiento_version?: string;
  anonimizado: boolean;
  activo: boolean;
}

export interface GoMeResponse {
  persona: GoPersona;
  roles: string[];
  permisos: string[];
}

export interface GoOrganizacion {
  id: number;
  nombre: string;
  tipo: string;
  codigo_modular_o_ref?: string;
  sector_ubicacion: string;
  responsable_id?: number;
  latitud?: number;
  longitud?: number;
  radio_metros: number;
}

export interface GoSesion {
  id: number;
  meta_anual_id: number;
  organizacion_id?: number;
  responsable_id: number;
  titulo: string;
  modalidad: string;
  eje_tematico: string;
  fecha_inicio: string;
  duracion_minutos: number;
  cupo_maximo: number;
  inscritos_actuales: number;
  cupos_disponibles: number;
  estado: string;
}

export interface GoAsistencia {
  sesion_id: number;
  persona_id: number;
  participacion: string;
  calificacion?: number;
  metodo_registro: string;
  distancia_metros?: number;
  registrado_at: string;
}

export interface GoSesionMonitoreo {
  sesion: GoSesion;
  qr_activo: boolean;
  qr_segundos_restantes: number;
  total_inscritos: number;
  total_asistentes: number;
  asistencias: GoAsistencia[];
}

export interface GoInscripcionSesion {
  id: number;
  sesion_id: number;
  persona_id: number;
  dni: string;
  nombres: string;
  apellidos: string;
  categoria?: string;
  estado: string;
  created_at: string;
}

export interface GoMetaAnual {
  id: number;
  anio: number;
  actividad_minam: string;
  indicador: string;
  meta_programada: number;
  presupuesto: number;
}

export interface GoQRResponse {
  sesion_id: number;
  qr_token: string;
  expires_at: string;
  segundos_restantes: number;
}

// --- Frontend View Models ---

export interface User {
  id: string;
  dni: string;
  nombres: string;
  apellidos: string;
  sexo?: 'M' | 'F';
  fechaNacimiento?: string;
  email: string;
  telefono: string;
  rol: UserRole;
  roles?: string[];
  permisos?: string[];
  categoria?: PromoterCategory | string;
  activo: boolean;
  fechaCreacion?: string;
}

export type VenueType =
  | 'MERCADO'
  | 'CENTRO_ACOPIO'
  | 'INSTITUCION_PUBLICA'
  | 'ESPACIO_PUBLICO_EPEA'
  | 'ORGANIZACION_SOCIAL'
  | 'COLEGIO'
  | 'EDUCACION_SUPERIOR';

export type VenueStatus = 'ACTIVO' | 'INACTIVO';

export interface Venue {
  id: string;
  numericId?: number;
  nombre: string;
  direccion: string;
  tipo: VenueType;
  latitud: number;
  longitud: number;
  radioMetros: number;
  estado: VenueStatus;
  talleresActivosCount?: number;
}

export type SessionStatus = 'PROGRAMADA' | 'EJECUTADA' | 'VALIDADA' | 'CANCELADA';
export type WorkshopStatus = SessionStatus;
export type SessionModalidad = 'PRESENCIAL' | 'VIRTUAL';

export interface Workshop {
  id: string;
  numericId?: number;
  nombre: string;
  sedeId: string;
  sedeNombre: string;
  fecha: string;
  horaInicio: string;
  horaFin: string;
  duracionMinutos?: number;
  modalidad: SessionModalidad;
  capacitadorId: string;
  capacitadorNombre: string;
  cuposTotales: number;
  cuposDisponibles: number;
  inscritos: number;
  estado: WorkshopStatus;
  ejeTematico: string;
  ejeTematicoCodigo: string;
  descripcion: string;
  metaAnualId?: number;
}

export interface SessionItem {
  id: string;
  numericId?: number;
  tallerId: string;
  tallerNombre: string;
  sedeId?: string;
  sedeNombre: string;
  fecha: string;
  hora: string;
  modalidad: SessionModalidad;
  estado: SessionStatus;
  capacitadorId?: string;
  capacitadorNombre: string;
  qrActivo: boolean;
  qrToken?: string;
  qrSegundosRestantes?: number;
  totalInscritos: number;
  totalAsistencias: number;
}

export type AttendanceStatus = 'PRESENTE' | 'PENDIENTE';
export type AttendanceMethod = 'QR_GPS' | 'MANUAL';
export type AttendanceParticipation = 'ASISTENTE' | 'VOLUNTARIO_REPLICA' | 'PONENTE';

export interface AttendanceRecord {
  id: string;
  sesionId: string;
  tallerNombre: string;
  sedeNombre: string;
  participanteId: string;
  participanteDni: string;
  participanteNombre: string;
  participanteCategoria: PromoterCategory | string;
  participacion: AttendanceParticipation;
  calificacion?: number;
  horaMarcado: string;
  fecha: string;
  estado: AttendanceStatus;
  metodo: AttendanceMethod;
  distanciaMetros?: number;
  validado: boolean;
  observaciones?: string;
}
