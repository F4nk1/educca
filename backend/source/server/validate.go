package server

import (
	"errors"
	"strings"

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

func validatePersonaFields(dni, nombres, apellidos, sexo string) error {
	if strings.TrimSpace(dni) == "" || strings.TrimSpace(nombres) == "" || strings.TrimSpace(apellidos) == "" {
		return errors.New("dni, nombres and apellidos are required")
	}
	if !validSexos[sexo] {
		return errors.New("sexo must be 'M' or 'F'")
	}
	return nil
}

func validateOrganizacion(o *model.Organizacion) error {
	if strings.TrimSpace(o.Nombre) == "" || strings.TrimSpace(o.SectorUbicacion) == "" {
		return errors.New("nombre and sector_ubicacion are required")
	}
	if !validTiposOrg[o.Tipo] {
		return errors.New("invalid organizacion tipo")
	}
	return nil
}

func validateMetaAnual(m *model.MetaAnual) error {
	if m.Anio < 2024 {
		return errors.New("anio must be >= 2024")
	}
	if !validActividades[m.ActividadMinam] {
		return errors.New("invalid actividad_minam")
	}
	if strings.TrimSpace(m.Indicador) == "" || m.MetaProgramada <= 0 {
		return errors.New("indicador and positive meta_programada are required")
	}
	return nil
}

func validatePromotorPeriodo(pp *model.PromotorPeriodo, requireEstado bool) error {
	if pp.PersonaId <= 0 || pp.Anio < 2024 {
		return errors.New("persona_id and valid anio are required")
	}
	if !validTiposPromotor[pp.TipoPromotor] {
		return errors.New("invalid tipo_promotor")
	}
	if pp.Estado != "" && !validEstadosPromotor[pp.Estado] {
		return errors.New("invalid estado")
	}
	if requireEstado && pp.Estado == "" {
		return errors.New("estado is required")
	}
	return nil
}

func validateSesionFields(metaAnualId, responsableId int64, titulo, modalidad string, duracionMinutos int16) error {
	if metaAnualId <= 0 || responsableId <= 0 || strings.TrimSpace(titulo) == "" || duracionMinutos <= 0 {
		return errors.New("meta_anual_id, responsable_id, titulo and positive duracion_minutos are required")
	}
	if !validModalidades[modalidad] {
		return errors.New("modalidad must be 'PRESENCIAL' or 'VIRTUAL'")
	}
	return nil
}

func validateAsistencia(a *model.Asistencia) error {
	if a.PersonaId <= 0 {
		return errors.New("persona_id is required")
	}
	if a.Participacion != "" && !validParticipaciones[a.Participacion] {
		return errors.New("invalid participacion")
	}
	return nil
}

func validateArchivoSesion(a *model.ArchivoSesion) error {
	if !validTiposArchivo[a.Tipo] {
		return errors.New("invalid archivo tipo")
	}
	if strings.TrimSpace(a.UrlArchivo) == "" {
		return errors.New("url_archivo is required")
	}
	return nil
}
