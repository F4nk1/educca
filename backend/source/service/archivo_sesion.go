package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func (s *service) ListArchivosSesion(ctx context.Context, sesionId int64) ([]model.ArchivoSesion, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, sesion_id, tipo, url_archivo FROM fn_archivo_sesion_listar($1)`,
		func(rows *sql.Rows) (model.ArchivoSesion, error) {
			var a model.ArchivoSesion
			err := rows.Scan(&a.Id, &a.SesionId, &a.Tipo, &a.UrlArchivo)
			return a, err
		},
		sesionId,
	)
}

func (s *service) CreateArchivoSesion(ctx context.Context, a *model.ArchivoSesion) (int64, error) {
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_archivo_sesion_crear($1, $2, $3)`,
		a.SesionId, a.Tipo, a.UrlArchivo,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) DeleteArchivoSesion(ctx context.Context, id, sesionId int64) error {
	return s.execBool(ctx, true, `SELECT fn_archivo_sesion_eliminar($1, $2)`, id, sesionId)
}
