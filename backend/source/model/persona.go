package model

import "time"

type Persona struct {
	Id              int64     `json:"id,omitempty" db:"id"`
	Dni             string    `json:"dni,omitempty" db:"dni"`
	Nombres         string    `json:"nombres,omitempty" db:"nombres"`
	Apellidos       string    `json:"apellidos,omitempty" db:"apellidos"`
	Sexo            string    `json:"sexo,omitempty" db:"sexo"`
	FechaNacimiento time.Time `json:"fecha_nacimiento,omitempty" db:"fecha_nacimiento"`
	Telefono        *string   `json:"telefono,omitempty" db:"telefono"`
	Email           *string   `json:"email,omitempty" db:"email"`
	PasswordHash    *string   `json:"-" db:"password_hash"`
	Activo          bool      `json:"activo" db:"activo"`
}
