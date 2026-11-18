package model

type ArchivoSesion struct {
	Id         int64  `json:"id" db:"id"`
	SesionId   int64  `json:"sesion_id" db:"sesion_id"`
	Tipo       string `json:"tipo" db:"tipo"`
	UrlArchivo string `json:"url_archivo" db:"url_archivo"`
}
