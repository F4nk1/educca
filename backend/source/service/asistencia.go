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
		`SELECT sesion_id, persona_id, participacion, calificacion, metodo_registro, distancia_metros, registrado_at FROM fn_asistencia_listar_por_sesion($1)`,
		func(rows *sql.Rows) (model.Asistencia, error) {
			var a model.Asistencia
			err := rows.Scan(
				&a.SesionId,
				&a.PersonaId,
				&a.Participacion,
				&a.Calificacion,
				&a.MetodoRegistro,
				&a.DistanciaMetros,
				&a.RegistradoAt,
			)
			return a, err
		},
		sesionId,
	)
}

func (s *service) ListAsistenciasByPersona(ctx context.Context, personaId int64) ([]model.MiAsistencia, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT sesion_id, titulo, eje_tematico, modalidad, fecha_inicio, estado_sesion, participacion, calificacion, metodo_registro, distancia_metros, registrado_at FROM fn_asistencia_listar_por_persona($1)`,
		func(rows *sql.Rows) (model.MiAsistencia, error) {
			var a model.MiAsistencia
			err := rows.Scan(
				&a.SesionId,
				&a.Titulo,
				&a.EjeTematico,
				&a.Modalidad,
				&a.FechaInicio,
				&a.EstadoSesion,
				&a.Participacion,
				&a.Calificacion,
				&a.MetodoRegistro,
				&a.DistanciaMetros,
				&a.RegistradoAt,
			)
			return a, err
		},
		personaId,
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
		a.SesionId,
		a.PersonaId,
		participacion,
		a.Calificacion,
	)
	return classifyError(err, false)
}

func (s *service) CheckInQR(ctx context.Context, sesionId, personaId int64, distanciaMetros float64) error {
	_, err := s.conn.Db.ExecContext(
		ctx,
		`SELECT fn_asistencia_checkin_qr($1, $2, $3)`,
		sesionId,
		personaId,
		distanciaMetros,
	)
	return classifyError(err, false)
}

func (s *service) DeleteAsistencia(ctx context.Context, sesionId, personaId int64) error {
	return s.execBool(ctx, true, `SELECT fn_asistencia_eliminar($1, $2)`, sesionId, personaId)
}
