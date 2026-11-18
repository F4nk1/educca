package model

type Asistencia struct {
	SesionId      int64    `json:"sesion_id" db:"sesion_id"`
	PersonaId     int64    `json:"persona_id" db:"persona_id"`
	Participacion string   `json:"participacion" db:"participacion"`
	Calificacion  *float64 `json:"calificacion,omitempty" db:"calificacion"`
}
