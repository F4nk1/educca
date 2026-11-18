package model

import "time"

type Persona struct {
	Id              int64     `json:"id" db:"id"`
	Dni             string    `json:"dni" db:"dni"`
	Nombres         string    `json:"nombres" db:"nombres"`
	Apellidos       string    `json:"apellidos" db:"apellidos"`
	Sexo            string    `json:"sexo" db:"sexo"`
	FechaNacimiento time.Time `json:"fecha_nacimiento" db:"fecha_nacimiento"`
	Telefono        *string   `json:"telefono,omitempty" db:"telefono"`
	Email           *string   `json:"email,omitempty" db:"email"`
	PasswordHash    *string   `json:"-" db:"password_hash"`
	Activo          bool      `json:"activo" db:"activo"`
}
