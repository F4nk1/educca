package model

import "time"

type Persona struct {
	Id                    int64      `json:"id" db:"id"`
	Dni                   string     `json:"dni" db:"dni"`
	Nombres               string     `json:"nombres" db:"nombres"`
	Apellidos             string     `json:"apellidos" db:"apellidos"`
	Sexo                  string     `json:"sexo" db:"sexo"`
	FechaNacimiento       time.Time  `json:"fecha_nacimiento" db:"fecha_nacimiento"`
	Telefono              *string    `json:"telefono,omitempty" db:"telefono"`
	Email                 *string    `json:"email,omitempty" db:"email"`
	PasswordHash          *string    `json:"-" db:"password_hash"`
	Categoria             *string    `json:"categoria,omitempty" db:"categoria"`
	ConsentimientoAt      *time.Time `json:"consentimiento_at,omitempty" db:"consentimiento_at"`
	ConsentimientoVersion *string    `json:"consentimiento_version,omitempty" db:"consentimiento_version"`
	Anonimizado           bool       `json:"anonimizado" db:"anonimizado"`
	Activo                bool       `json:"activo" db:"activo"`
}

type ArcoExport struct {
	Persona       Persona        `json:"persona"`
	Roles         []string       `json:"roles"`
	Inscripciones []MiInscripcion `json:"inscripciones"`
	Asistencias   []MiAsistencia  `json:"asistencias"`
	ExportadoAt   time.Time      `json:"exportado_at"`
}
