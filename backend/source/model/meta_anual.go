package model

type MetaAnual struct {
	Id             int64   `json:"id,omitempty" db:"id"`
	Anio           int16   `json:"anio,omitempty" db:"anio"`
	ActividadMinam string  `json:"actividad_minam,omitempty" db:"actividad_minam"`
	Indicador      string  `json:"indicador,omitempty" db:"indicador"`
	MetaProgramada int32   `json:"meta_programada,omitempty" db:"meta_programada"`
	Presupuesto    float64 `json:"presupuesto" db:"presupuesto"`
}
