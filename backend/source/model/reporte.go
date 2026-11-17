package model

type ReporteAvanceMeta struct {
	MetaAnualId         int64   `json:"meta_anual_id" db:"meta_anual_id"`
	Anio                int16   `json:"anio" db:"anio"`
	ActividadMinam      string  `json:"actividad_minam" db:"actividad_minam"`
	Indicador           string  `json:"indicador" db:"indicador"`
	MetaProgramada      int32   `json:"meta_programada" db:"meta_programada"`
	Presupuesto         float64 `json:"presupuesto" db:"presupuesto"`
	SesionesProgramadas int64   `json:"sesiones_programadas" db:"sesiones_programadas"`
	SesionesEjecutadas  int64   `json:"sesiones_ejecutadas" db:"sesiones_ejecutadas"`
	SesionesValidadas   int64   `json:"sesiones_validadas" db:"sesiones_validadas"`
	TotalAsistentes     int64   `json:"total_asistentes" db:"total_asistentes"`
}
