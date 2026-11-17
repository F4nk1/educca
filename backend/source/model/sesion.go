package model

import "time"

type Sesion struct {
	Id              int64     `json:"id,omitempty" db:"id"`
	MetaAnualId     int64     `json:"meta_anual_id,omitempty" db:"meta_anual_id"`
	OrganizacionId  *int64    `json:"organizacion_id,omitempty" db:"organizacion_id"`
	ResponsableId   int64     `json:"responsable_id,omitempty" db:"responsable_id"`
	Titulo          string    `json:"titulo,omitempty" db:"titulo"`
	Modalidad       string    `json:"modalidad,omitempty" db:"modalidad"`
	FechaInicio     time.Time `json:"fecha_inicio,omitempty" db:"fecha_inicio"`
	DuracionMinutos int16     `json:"duracion_minutos,omitempty" db:"duracion_minutos"`
	Estado          string    `json:"estado,omitempty" db:"estado"`
}
