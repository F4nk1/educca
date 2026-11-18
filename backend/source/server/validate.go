package server

import (
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

var (
	validSexos           = map[string]bool{"M": true, "F": true}
	validTiposOrg        = map[string]bool{"COLEGIO": true, "EDUCACION_SUPERIOR": true, "ORGANIZACION_SOCIAL": true, "ESPACIO_PUBLICO_EPEA": true, "INSTITUCION_PUBLICA": true}
	validActividades     = map[string]bool{"PAE": true, "PAJ": true, "PAC": true, "EPEA": true, "CAMPANA": true}
	validTiposPromotor   = map[string]bool{"PAE": true, "PAJ": true, "PAC": true, "DOCENTE": true}
	validEstadosPromotor = map[string]bool{"INSCRITO": true, "ACREDITADO": true, "RETIRADO": true}
	validModalidades     = map[string]bool{"PRESENCIAL": true, "VIRTUAL": true}
	validEstadosSesion   = map[string]bool{"PROGRAMADA": true, "EJECUTADA": true, "VALIDADA": true, "CANCELADA": true}
	validParticipaciones = map[string]bool{"ASISTENTE": true, "VOLUNTARIO_REPLICA": true, "PONENTE": true}
	validTiposArchivo    = map[string]bool{"FOTO_EVIDENCIA": true, "PADRON_FIRMADO": true, "ACTA": true, "MATERIAL_DIDACTICO": true}
)

func normalizeOptionalString(s *string) *string {
	if s == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*s)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func validatePersonaFields(dni, nombres, apellidos, sexo string) (int, string) {
	if strings.TrimSpace(dni) == "" || strings.TrimSpace(nombres) == "" || strings.TrimSpace(apellidos) == "" || strings.TrimSpace(sexo) == "" {
		return common.MISSING_FIELDS_ERROR, "dni, nombres, apellidos and sexo are required"
	}
	if !validSexos[sexo] {
		return common.INVALID_REQUEST_ERROR, "sexo must be 'M' or 'F'"
	}
	return 0, ""
}

func validateOrganizacion(o *model.Organizacion) (int, string) {
	if strings.TrimSpace(o.Nombre) == "" || strings.TrimSpace(o.SectorUbicacion) == "" || strings.TrimSpace(o.Tipo) == "" {
		return common.MISSING_FIELDS_ERROR, "nombre, tipo and sector_ubicacion are required"
	}
	if !validTiposOrg[o.Tipo] {
		return common.INVALID_REQUEST_ERROR, "invalid organizacion tipo"
	}
	o.CodigoModularORef = normalizeOptionalString(o.CodigoModularORef)
	return 0, ""
}

func validateMetaAnual(m *model.MetaAnual) (int, string) {
	if m.Anio == 0 || strings.TrimSpace(m.ActividadMinam) == "" || strings.TrimSpace(m.Indicador) == "" || m.MetaProgramada == 0 {
		return common.MISSING_FIELDS_ERROR, "anio, actividad_minam, indicador and meta_programada are required"
	}
	if m.Anio < 2024 {
		return common.INVALID_REQUEST_ERROR, "anio must be >= 2024"
	}
	if !validActividades[m.ActividadMinam] {
		return common.INVALID_REQUEST_ERROR, "invalid actividad_minam"
	}
	if m.MetaProgramada <= 0 {
		return common.INVALID_REQUEST_ERROR, "meta_programada must be > 0"
	}
	if m.Presupuesto < 0 {
		return common.INVALID_REQUEST_ERROR, "presupuesto must be >= 0"
	}
	return 0, ""
}

func validatePromotorPeriodo(pp *model.PromotorPeriodo, requireEstado bool) (int, string) {
	if pp.PersonaId <= 0 || pp.Anio == 0 || strings.TrimSpace(pp.TipoPromotor) == "" {
		return common.MISSING_FIELDS_ERROR, "persona_id, anio and tipo_promotor are required"
	}
	if requireEstado && strings.TrimSpace(pp.Estado) == "" {
		return common.MISSING_FIELDS_ERROR, "estado is required"
	}
	if pp.Anio < 2024 {
		return common.INVALID_REQUEST_ERROR, "anio must be >= 2024"
	}
	if !validTiposPromotor[pp.TipoPromotor] {
		return common.INVALID_REQUEST_ERROR, "invalid tipo_promotor"
	}
	if pp.Estado != "" && !validEstadosPromotor[pp.Estado] {
		return common.INVALID_REQUEST_ERROR, "invalid estado"
	}
	pp.CodigoCertificado = normalizeOptionalString(pp.CodigoCertificado)
	return 0, ""
}

func validateSesionFields(metaAnualId, responsableId int64, titulo, modalidad string, duracionMinutos int16) (int, string) {
	if metaAnualId <= 0 || responsableId <= 0 || strings.TrimSpace(titulo) == "" || strings.TrimSpace(modalidad) == "" || duracionMinutos == 0 {
		return common.MISSING_FIELDS_ERROR, "meta_anual_id, responsable_id, titulo, modalidad and duracion_minutos are required"
	}
	if duracionMinutos <= 0 {
		return common.INVALID_REQUEST_ERROR, "duracion_minutos must be > 0"
	}
	if !validModalidades[modalidad] {
		return common.INVALID_REQUEST_ERROR, "modalidad must be 'PRESENCIAL' or 'VIRTUAL'"
	}
	return 0, ""
}

func validateAsistencia(a *model.Asistencia) (int, string) {
	if a.PersonaId <= 0 {
		return common.MISSING_FIELDS_ERROR, "persona_id is required"
	}
	if a.Participacion != "" && !validParticipaciones[a.Participacion] {
		return common.INVALID_REQUEST_ERROR, "invalid participacion"
	}
	if a.Calificacion != nil && (*a.Calificacion < 0 || *a.Calificacion > 20) {
		return common.INVALID_REQUEST_ERROR, "calificacion must be between 0 and 20"
	}
	return 0, ""
}

func validateArchivoSesion(a *model.ArchivoSesion) (int, string) {
	if strings.TrimSpace(a.Tipo) == "" || strings.TrimSpace(a.UrlArchivo) == "" {
		return common.MISSING_FIELDS_ERROR, "tipo and url_archivo are required"
	}
	if !validTiposArchivo[a.Tipo] {
		return common.INVALID_REQUEST_ERROR, "invalid archivo tipo"
	}
	return 0, ""
}
