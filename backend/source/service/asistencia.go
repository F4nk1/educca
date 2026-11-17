package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func (s *service) ListAsistencias(ctx context.Context, sesionId int64) ([]model.Asistencia, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT sesion_id, persona_id, participacion, calificacion FROM fn_asistencia_listar_por_sesion($1)`,
		func(rows *sql.Rows) (model.Asistencia, error) {
			var a model.Asistencia
			err := rows.Scan(&a.SesionId, &a.PersonaId, &a.Participacion, &a.Calificacion)
			return a, err
		},
		sesionId,
	)
}

func (s *service) UpsertAsistencia(ctx context.Context, a *model.Asistencia) error {
	var participacion *string
	if a.Participacion != "" {
		participacion = &a.Participacion
	}
	_, err := s.conn.Db.ExecContext(
		ctx,
		`SELECT fn_asistencia_registrar($1, $2, $3, $4)`,
		a.SesionId, a.PersonaId, participacion, a.Calificacion,
	)
	return classifyError(err, false)
}

func (s *service) DeleteAsistencia(ctx context.Context, sesionId, personaId int64) error {
	return s.execBool(ctx, true, `SELECT fn_asistencia_eliminar($1, $2)`, sesionId, personaId)
}
