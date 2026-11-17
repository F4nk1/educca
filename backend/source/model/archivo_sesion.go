package model

type ArchivoSesion struct {
	Id         int64  `json:"id,omitempty" db:"id"`
	SesionId   int64  `json:"sesion_id,omitempty" db:"sesion_id"`
	Tipo       string `json:"tipo,omitempty" db:"tipo"`
	UrlArchivo string `json:"url_archivo,omitempty" db:"url_archivo"`
}
