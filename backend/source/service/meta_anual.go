package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanMetaAnual(s interface{ Scan(...any) error }) (model.MetaAnual, error) {
	var m model.MetaAnual
	err := s.Scan(&m.Id, &m.Anio, &m.ActividadMinam, &m.Indicador, &m.MetaProgramada, &m.Presupuesto)
	return m, err
}

func (s *service) ListMetasAnuales(ctx context.Context, anio *int16) ([]model.MetaAnual, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, anio, actividad_minam, indicador, meta_programada, presupuesto FROM fn_meta_anual_listar($1)`,
		func(rows *sql.Rows) (model.MetaAnual, error) { return scanMetaAnual(rows) },
		anio,
	)
}

func (s *service) GetMetaAnual(ctx context.Context, id int64) (*model.MetaAnual, error) {
	m, err := scanMetaAnual(s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, anio, actividad_minam, indicador, meta_programada, presupuesto FROM fn_meta_anual_obtener($1)`,
		id,
	))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &m, nil
}

func (s *service) CreateMetaAnual(ctx context.Context, m *model.MetaAnual) (int64, error) {
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_meta_anual_crear($1, $2, $3, $4, $5)`,
		m.Anio, m.ActividadMinam, m.Indicador, m.MetaProgramada, m.Presupuesto,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdateMetaAnual(ctx context.Context, m *model.MetaAnual) error {
	return s.execBool(
		ctx,
		false,
		`SELECT fn_meta_anual_actualizar($1, $2, $3, $4, $5, $6)`,
		m.Id, m.Anio, m.ActividadMinam, m.Indicador, m.MetaProgramada, m.Presupuesto,
	)
}

func (s *service) DeleteMetaAnual(ctx context.Context, id int64) error {
	return s.execBool(ctx, true, `SELECT fn_meta_anual_eliminar($1)`, id)
}
