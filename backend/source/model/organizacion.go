package model

type Organizacion struct {
	Id                int64   `json:"id,omitempty" db:"id"`
	Nombre            string  `json:"nombre,omitempty" db:"nombre"`
	Tipo              string  `json:"tipo,omitempty" db:"tipo"`
	CodigoModularORef *string `json:"codigo_modular_o_ref,omitempty" db:"codigo_modular_o_ref"`
	SectorUbicacion   string  `json:"sector_ubicacion,omitempty" db:"sector_ubicacion"`
	ResponsableId     *int64  `json:"responsable_id,omitempty" db:"responsable_id"`
}
