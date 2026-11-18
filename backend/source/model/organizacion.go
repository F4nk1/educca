package model

type Organizacion struct {
	Id                int64    `json:"id" db:"id"`
	Nombre            string   `json:"nombre" db:"nombre"`
	Tipo              string   `json:"tipo" db:"tipo"`
	CodigoModularORef *string  `json:"codigo_modular_o_ref,omitempty" db:"codigo_modular_o_ref"`
	SectorUbicacion   string   `json:"sector_ubicacion" db:"sector_ubicacion"`
	ResponsableId     *int64   `json:"responsable_id,omitempty" db:"responsable_id"`
	Latitud           *float64 `json:"latitud,omitempty" db:"latitud"`
	Longitud          *float64 `json:"longitud,omitempty" db:"longitud"`
	RadioMetros       int      `json:"radio_metros" db:"radio_metros"`
}
