package model

type Rol struct {
	Id          int16  `json:"id,omitempty" db:"id"`
	Nombre      string `json:"nombre,omitempty" db:"nombre"`
	Descripcion string `json:"descripcion,omitempty" db:"descripcion"`
}

type Permiso struct {
	Id          int16  `json:"id,omitempty" db:"id"`
	Clave       string `json:"clave,omitempty" db:"clave"`
	Descripcion string `json:"descripcion,omitempty" db:"descripcion"`
}

type RolPermiso struct {
	RolId     int16 `json:"rol_id" db:"rol_id"`
	PermisoId int16 `json:"permiso_id" db:"permiso_id"`
}

type PersonaRol struct {
	PersonaId int64 `json:"persona_id" db:"persona_id"`
	RolId     int16 `json:"rol_id" db:"rol_id"`
}
