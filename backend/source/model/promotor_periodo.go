package model

type PromotorPeriodo struct {
	Id                int64   `json:"id" db:"id"`
	PersonaId         int64   `json:"persona_id" db:"persona_id"`
	Anio              int16   `json:"anio" db:"anio"`
	TipoPromotor      string  `json:"tipo_promotor" db:"tipo_promotor"`
	OrganizacionId    *int64  `json:"organizacion_id,omitempty" db:"organizacion_id"`
	Estado            string  `json:"estado" db:"estado"`
	CodigoCertificado *string `json:"codigo_certificado,omitempty" db:"codigo_certificado"`
}
