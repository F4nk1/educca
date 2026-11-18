package model

type Rol struct {
	Id          int16  `json:"id" db:"id"`
	Nombre      string `json:"nombre" db:"nombre"`
	Descripcion string `json:"descripcion" db:"descripcion"`
}

type Permiso struct {
	Id          int16  `json:"id" db:"id"`
	Clave       string `json:"clave" db:"clave"`
	Descripcion string `json:"descripcion" db:"descripcion"`
}
