package model

type PromotorPeriodo struct {
	Id                int64   `json:"id,omitempty" db:"id"`
	PersonaId         int64   `json:"persona_id,omitempty" db:"persona_id"`
	Anio              int16   `json:"anio,omitempty" db:"anio"`
	TipoPromotor      string  `json:"tipo_promotor,omitempty" db:"tipo_promotor"`
	OrganizacionId    *int64  `json:"organizacion_id,omitempty" db:"organizacion_id"`
	Estado            string  `json:"estado,omitempty" db:"estado"`
	CodigoCertificado *string `json:"codigo_certificado,omitempty" db:"codigo_certificado"`
}
