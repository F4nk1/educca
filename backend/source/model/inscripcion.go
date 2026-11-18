package model

import "time"

type InscripcionSesion struct {
	Id        int64     `json:"id" db:"id"`
	SesionId  int64     `json:"sesion_id" db:"sesion_id"`
	PersonaId int64     `json:"persona_id" db:"persona_id"`
	Dni       string    `json:"dni" db:"dni"`
	Nombres   string    `json:"nombres" db:"nombres"`
	Apellidos string    `json:"apellidos" db:"apellidos"`
	Categoria *string   `json:"categoria,omitempty" db:"categoria"`
	Estado    string    `json:"estado" db:"estado"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type MiInscripcion struct {
	Id              int64     `json:"id" db:"id"`
	SesionId        int64     `json:"sesion_id" db:"sesion_id"`
	Titulo          string    `json:"titulo" db:"titulo"`
	EjeTematico     string    `json:"eje_tematico" db:"eje_tematico"`
	Modalidad       string    `json:"modalidad" db:"modalidad"`
	FechaInicio     time.Time `json:"fecha_inicio" db:"fecha_inicio"`
	DuracionMinutos int16     `json:"duracion_minutos" db:"duracion_minutos"`
	OrganizacionId  *int64    `json:"organizacion_id,omitempty" db:"organizacion_id"`
	EstadoSesion    string    `json:"estado_sesion" db:"estado_sesion"`
	Estado          string    `json:"estado" db:"estado"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
}
