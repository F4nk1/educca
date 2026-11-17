package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func (s *service) GetReporteAvanceMetas(ctx context.Context, anio *int16) ([]model.ReporteAvanceMeta, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT meta_anual_id, anio, actividad_minam, indicador, meta_programada, presupuesto, sesiones_programadas, sesiones_ejecutadas, sesiones_validadas, total_asistentes FROM fn_reporte_avance_metas($1)`,
		func(rows *sql.Rows) (model.ReporteAvanceMeta, error) {
			var r model.ReporteAvanceMeta
			err := rows.Scan(
				&r.MetaAnualId, &r.Anio, &r.ActividadMinam, &r.Indicador, &r.MetaProgramada, &r.Presupuesto,
				&r.SesionesProgramadas, &r.SesionesEjecutadas, &r.SesionesValidadas, &r.TotalAsistentes,
			)
			return r, err
		},
		anio,
	)
}
