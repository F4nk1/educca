package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanPromotorPeriodo(s interface{ Scan(...any) error }) (model.PromotorPeriodo, error) {
	var pp model.PromotorPeriodo
	err := s.Scan(&pp.Id, &pp.PersonaId, &pp.Anio, &pp.TipoPromotor, &pp.OrganizacionId, &pp.Estado, &pp.CodigoCertificado)
	return pp, err
}

func (s *service) ListPromotoresPeriodo(ctx context.Context, anio *int16) ([]model.PromotorPeriodo, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, persona_id, anio, tipo_promotor, organizacion_id, estado, codigo_certificado FROM fn_promotor_periodo_listar($1)`,
		func(rows *sql.Rows) (model.PromotorPeriodo, error) { return scanPromotorPeriodo(rows) },
		anio,
	)
}

func (s *service) GetPromotorPeriodo(ctx context.Context, id int64) (*model.PromotorPeriodo, error) {
	pp, err := scanPromotorPeriodo(s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, persona_id, anio, tipo_promotor, organizacion_id, estado, codigo_certificado FROM fn_promotor_periodo_obtener($1)`,
		id,
	))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &pp, nil
}

func (s *service) CreatePromotorPeriodo(ctx context.Context, pp *model.PromotorPeriodo) (int64, error) {
	var estado *string
	if pp.Estado != "" {
		estado = &pp.Estado
	}
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_promotor_periodo_crear($1, $2, $3, $4, $5, $6)`,
		pp.PersonaId, pp.Anio, pp.TipoPromotor, pp.OrganizacionId, estado, pp.CodigoCertificado,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdatePromotorPeriodo(ctx context.Context, pp *model.PromotorPeriodo) error {
	return s.execBool(
		ctx,
		false,
		`SELECT fn_promotor_periodo_actualizar($1, $2, $3, $4, $5, $6, $7)`,
		pp.Id, pp.PersonaId, pp.Anio, pp.TipoPromotor, pp.OrganizacionId, pp.Estado, pp.CodigoCertificado,
	)
}

func (s *service) DeletePromotorPeriodo(ctx context.Context, id int64) error {
	return s.execBool(ctx, true, `SELECT fn_promotor_periodo_eliminar($1)`, id)
}
