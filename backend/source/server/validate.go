package server

import (
	"net/mail"
	"regexp"
	"strings"
	"time"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

var (
	dniRegex = regexp.MustCompile(`^[0-9A-Za-z-]{8,15}$`)

	validSexos                = map[string]bool{"M": true, "F": true}
	validTiposOrg             = map[string]bool{"COLEGIO": true, "EDUCACION_SUPERIOR": true, "ORGANIZACION_SOCIAL": true, "ESPACIO_PUBLICO_EPEA": true, "INSTITUCION_PUBLICA": true, "MERCADO": true, "CENTRO_ACOPIO": true}
	validActividades          = map[string]bool{"PAE": true, "PAJ": true, "PAC": true, "EPEA": true, "CAMPANA": true}
	validTiposPromotor        = map[string]bool{"PAE": true, "PAJ": true, "PAC": true, "DOCENTE": true, "COMERCIANTE": true, "RECICLADOR": true}
	validCategoriasCiudadanas = map[string]bool{"COMERCIANTE": true, "RECICLADOR": true, "PAC": true, "PAJ": true}
	validEstadosPromotor      = map[string]bool{"INSCRITO": true, "ACREDITADO": true, "RETIRADO": true}
	validModalidades          = map[string]bool{"PRESENCIAL": true, "VIRTUAL": true}
	validEjesTematicos        = map[string]bool{"SEGREGACION_RECICLA": true, "RECICLAJE_FORMAL": true, "COMPOSTAJE": true, "ECOEFICIENCIA": true, "GESTION_RESIDUOS": true}
	validEstadosSesion        = map[string]bool{"PROGRAMADA": true, "EJECUTADA": true, "VALIDADA": true, "CANCELADA": true}
	validParticipaciones      = map[string]bool{"ASISTENTE": true, "VOLUNTARIO_REPLICA": true, "PONENTE": true}
	validTiposArchivo         = map[string]bool{"FOTO_EVIDENCIA": true, "PADRON_FIRMADO": true, "ACTA": true, "MATERIAL_DIDACTICO": true}
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

func isValidDNI(dni string) bool {
	return dniRegex.MatchString(strings.TrimSpace(dni))
}

func isValidEmail(raw string) bool {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" || len(trimmed) > 120 {
		return false
	}
	addr, err := mail.ParseAddress(trimmed)
	if err != nil || addr.Address != trimmed {
		return false
	}
	parts := strings.Split(trimmed, "@")
	return len(parts) == 2 && strings.Contains(parts[1], ".") && !strings.HasPrefix(parts[1], ".") && !strings.HasSuffix(parts[1], ".")
}

func isAdultAt(fechaNacimiento time.Time, now time.Time) bool {
	nowPeru := now.In(peruLocation)
	nacPeru := fechaNacimiento.In(peruLocation)
	if nacPeru.Year() < 1900 || nacPeru.After(nowPeru) {
		return false
	}
	cutoff := time.Date(nowPeru.Year()-18, nowPeru.Month(), nowPeru.Day(), 23, 59, 59, 0, peruLocation)
	return !nacPeru.After(cutoff)
}

func validateCoordinates(lat, lon *float64) (int, string) {
	if lat == nil && lon == nil {
		return 0, ""
	}
	if lat == nil || lon == nil {
		return common.INVALID_REQUEST_ERROR, "latitud and longitud must both be provided together"
	}
	if *lat < -90 || *lat > 90 {
		return common.INVALID_REQUEST_ERROR, "latitud must be between -90 and 90"
	}
	if *lon < -180 || *lon > 180 {
		return common.INVALID_REQUEST_ERROR, "longitud must be between -180 and 180"
	}
	return 0, ""
}

func validatePersonaFields(dni, nombres, apellidos, sexo string, email *string, categoria *string) (int, string) {
	if strings.TrimSpace(dni) == "" || strings.TrimSpace(nombres) == "" || strings.TrimSpace(apellidos) == "" || strings.TrimSpace(sexo) == "" {
		return common.MISSING_FIELDS_ERROR, "dni, nombres, apellidos and sexo are required"
	}
	if !isValidDNI(dni) {
		return common.INVALID_REQUEST_ERROR, "dni must contain between 8 and 15 alphanumeric characters"
	}
	if !validSexos[sexo] {
		return common.INVALID_REQUEST_ERROR, "sexo must be 'M' or 'F'"
	}
	if email != nil && strings.TrimSpace(*email) != "" && !isValidEmail(*email) {
		return common.INVALID_REQUEST_ERROR, "invalid email format"
	}
	if categoria != nil && strings.TrimSpace(*categoria) != "" && !validCategoriasCiudadanas[strings.TrimSpace(*categoria)] {
		return common.INVALID_REQUEST_ERROR, "categoria must be 'COMERCIANTE', 'RECICLADOR', 'PAC' or 'PAJ'"
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
	if code, msg := validateCoordinates(o.Latitud, o.Longitud); code != 0 {
		return code, msg
	}
	if o.RadioMetros < 0 {
		return common.INVALID_REQUEST_ERROR, "radio_metros must be > 0"
	}
	if o.RadioMetros == 0 {
		o.RadioMetros = 80
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

func validateSesionFields(metaAnualId, responsableId int64, titulo, modalidad, ejeTematico string, duracionMinutos int16, cupoMaximo int) (int, string) {
	if metaAnualId <= 0 || responsableId <= 0 || strings.TrimSpace(titulo) == "" || strings.TrimSpace(modalidad) == "" || duracionMinutos == 0 {
		return common.MISSING_FIELDS_ERROR, "meta_anual_id, responsable_id, titulo, modalidad and duracion_minutos are required"
	}
	if duracionMinutos <= 0 {
		return common.INVALID_REQUEST_ERROR, "duracion_minutos must be > 0"
	}
	if !validModalidades[modalidad] {
		return common.INVALID_REQUEST_ERROR, "modalidad must be 'PRESENCIAL' or 'VIRTUAL'"
	}
	if ejeTematico != "" && !validEjesTematicos[ejeTematico] {
		return common.INVALID_REQUEST_ERROR, "invalid eje_tematico"
	}
	if cupoMaximo < 0 {
		return common.INVALID_REQUEST_ERROR, "cupo_maximo must be > 0"
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
