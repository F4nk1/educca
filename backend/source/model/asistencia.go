package model

import "time"

type Asistencia struct {
	SesionId        int64     `json:"sesion_id" db:"sesion_id"`
	PersonaId       int64     `json:"persona_id" db:"persona_id"`
	Participacion   string    `json:"participacion" db:"participacion"`
	Calificacion    *float64  `json:"calificacion,omitempty" db:"calificacion"`
	MetodoRegistro  string    `json:"metodo_registro" db:"metodo_registro"`
	DistanciaMetros *float64  `json:"distancia_metros,omitempty" db:"distancia_metros"`
	RegistradoAt    time.Time `json:"registrado_at" db:"registrado_at"`
}

type MiAsistencia struct {
	SesionId        int64     `json:"sesion_id" db:"sesion_id"`
	Titulo          string    `json:"titulo" db:"titulo"`
	EjeTematico     string    `json:"eje_tematico" db:"eje_tematico"`
	Modalidad       string    `json:"modalidad" db:"modalidad"`
	FechaInicio     time.Time `json:"fecha_inicio" db:"fecha_inicio"`
	EstadoSesion    string    `json:"estado_sesion" db:"estado_sesion"`
	Participacion   string    `json:"participacion" db:"participacion"`
	Calificacion    *float64  `json:"calificacion,omitempty" db:"calificacion"`
	MetodoRegistro  string    `json:"metodo_registro" db:"metodo_registro"`
	DistanciaMetros *float64  `json:"distancia_metros,omitempty" db:"distancia_metros"`
	RegistradoAt    time.Time `json:"registrado_at" db:"registrado_at"`
}
