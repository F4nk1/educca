package model

import "time"

type Sesion struct {
	Id              int64     `json:"id" db:"id"`
	MetaAnualId     int64     `json:"meta_anual_id" db:"meta_anual_id"`
	OrganizacionId  *int64    `json:"organizacion_id,omitempty" db:"organizacion_id"`
	ResponsableId   int64     `json:"responsable_id" db:"responsable_id"`
	Titulo          string    `json:"titulo" db:"titulo"`
	Modalidad       string    `json:"modalidad" db:"modalidad"`
	FechaInicio     time.Time `json:"fecha_inicio" db:"fecha_inicio"`
	DuracionMinutos int16     `json:"duracion_minutos" db:"duracion_minutos"`
	Estado          string    `json:"estado" db:"estado"`
}
