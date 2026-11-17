package model

type Asistencia struct {
	SesionId      int64    `json:"sesion_id,omitempty" db:"sesion_id"`
	PersonaId     int64    `json:"persona_id,omitempty" db:"persona_id"`
	Participacion string   `json:"participacion,omitempty" db:"participacion"`
	Calificacion  *float64 `json:"calificacion,omitempty" db:"calificacion"`
}
