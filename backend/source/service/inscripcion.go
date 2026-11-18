package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func (s *service) CreateInscripcion(ctx context.Context, sesionId, personaId int64) (int64, error) {
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_inscripcion_crear($1, $2)`,
		sesionId,
		personaId,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) CancelInscripcion(ctx context.Context, sesionId, personaId int64) error {
	return s.execBool(ctx, true, `SELECT fn_inscripcion_cancelar($1, $2)`, sesionId, personaId)
}

func (s *service) ListInscripcionesBySesion(ctx context.Context, sesionId int64) ([]model.InscripcionSesion, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, sesion_id, persona_id, dni, nombres, apellidos, categoria, estado, created_at FROM fn_inscripcion_listar_por_sesion($1)`,
		func(rows *sql.Rows) (model.InscripcionSesion, error) {
			var item model.InscripcionSesion
			err := rows.Scan(
				&item.Id,
				&item.SesionId,
				&item.PersonaId,
				&item.Dni,
				&item.Nombres,
				&item.Apellidos,
				&item.Categoria,
				&item.Estado,
				&item.CreatedAt,
			)
			return item, err
		},
		sesionId,
	)
}

func (s *service) ListInscripcionesByPersona(ctx context.Context, personaId int64) ([]model.MiInscripcion, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, sesion_id, titulo, eje_tematico, modalidad, fecha_inicio, duracion_minutos, organizacion_id, estado_sesion, estado, created_at FROM fn_inscripcion_listar_por_persona($1)`,
		func(rows *sql.Rows) (model.MiInscripcion, error) {
			var item model.MiInscripcion
			err := rows.Scan(
				&item.Id,
				&item.SesionId,
				&item.Titulo,
				&item.EjeTematico,
				&item.Modalidad,
				&item.FechaInicio,
				&item.DuracionMinutos,
				&item.OrganizacionId,
				&item.EstadoSesion,
				&item.Estado,
				&item.CreatedAt,
			)
			return item, err
		},
		personaId,
	)
}
