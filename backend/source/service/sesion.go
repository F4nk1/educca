package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanSesion(s interface{ Scan(...any) error }) (model.Sesion, error) {
	var ses model.Sesion
	err := s.Scan(
		&ses.Id, &ses.MetaAnualId, &ses.OrganizacionId, &ses.ResponsableId,
		&ses.Titulo, &ses.Modalidad, &ses.FechaInicio, &ses.DuracionMinutos, &ses.Estado,
	)
	return ses, err
}

func (s *service) ListSesiones(ctx context.Context, metaAnualId *int64, estado *string) ([]model.Sesion, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, meta_anual_id, organizacion_id, responsable_id, titulo, modalidad, fecha_inicio, duracion_minutos, estado FROM fn_sesion_listar($1, $2)`,
		func(rows *sql.Rows) (model.Sesion, error) { return scanSesion(rows) },
		metaAnualId, estado,
	)
}

func (s *service) GetSesion(ctx context.Context, id int64) (*model.Sesion, error) {
	ses, err := scanSesion(s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, meta_anual_id, organizacion_id, responsable_id, titulo, modalidad, fecha_inicio, duracion_minutos, estado FROM fn_sesion_obtener($1)`,
		id,
	))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &ses, nil
}

func (s *service) CreateSesion(ctx context.Context, ses *model.Sesion) (int64, error) {
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_sesion_crear($1, $2, $3, $4, $5, $6, $7)`,
		ses.MetaAnualId, ses.OrganizacionId, ses.ResponsableId,
		ses.Titulo, ses.Modalidad, ses.FechaInicio, ses.DuracionMinutos,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdateSesion(ctx context.Context, ses *model.Sesion) error {
	return s.execBool(
		ctx,
		false,
		`SELECT fn_sesion_actualizar($1, $2, $3, $4, $5, $6, $7, $8)`,
		ses.Id, ses.MetaAnualId, ses.OrganizacionId, ses.ResponsableId,
		ses.Titulo, ses.Modalidad, ses.FechaInicio, ses.DuracionMinutos,
	)
}

func (s *service) ChangeSesionEstado(ctx context.Context, id int64, estado string) error {
	return s.execBool(ctx, false, `SELECT fn_sesion_cambiar_estado($1, $2)`, id, estado)
}

func (s *service) DeleteSesion(ctx context.Context, id int64) error {
	return s.execBool(ctx, true, `SELECT fn_sesion_eliminar($1)`, id)
}
