package model

import "time"

type Sesion struct {
	Id                int64     `json:"id" db:"id"`
	MetaAnualId       int64     `json:"meta_anual_id" db:"meta_anual_id"`
	OrganizacionId    *int64    `json:"organizacion_id,omitempty" db:"organizacion_id"`
	ResponsableId     int64     `json:"responsable_id" db:"responsable_id"`
	Titulo            string    `json:"titulo" db:"titulo"`
	Modalidad         string    `json:"modalidad" db:"modalidad"`
	EjeTematico       string    `json:"eje_tematico" db:"eje_tematico"`
	FechaInicio       time.Time `json:"fecha_inicio" db:"fecha_inicio"`
	DuracionMinutos   int16     `json:"duracion_minutos" db:"duracion_minutos"`
	CupoMaximo        int       `json:"cupo_maximo" db:"cupo_maximo"`
	InscritosActuales int       `json:"inscritos_actuales" db:"inscritos_actuales"`
	CuposDisponibles  int       `json:"cupos_disponibles" db:"cupos_disponibles"`
	Estado            string    `json:"estado" db:"estado"`
}

type SesionMonitoreo struct {
	Sesion              Sesion       `json:"sesion"`
	QRActivo            bool         `json:"qr_activo"`
	QRSegundosRestantes int64        `json:"qr_segundos_restantes"`
	TotalInscritos      int          `json:"total_inscritos"`
	TotalAsistentes     int          `json:"total_asistentes"`
	Asistencias         []Asistencia `json:"asistencias"`
}
