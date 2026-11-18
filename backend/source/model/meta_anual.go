package model

type MetaAnual struct {
	Id             int64   `json:"id" db:"id"`
	Anio           int16   `json:"anio" db:"anio"`
	ActividadMinam string  `json:"actividad_minam" db:"actividad_minam"`
	Indicador      string  `json:"indicador" db:"indicador"`
	MetaProgramada int32   `json:"meta_programada" db:"meta_programada"`
	Presupuesto    float64 `json:"presupuesto" db:"presupuesto"`
}
