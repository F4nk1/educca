package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanOrganizacion(s interface{ Scan(...any) error }) (model.Organizacion, error) {
	var o model.Organizacion
	err := s.Scan(
		&o.Id,
		&o.Nombre,
		&o.Tipo,
		&o.CodigoModularORef,
		&o.SectorUbicacion,
		&o.ResponsableId,
		&o.Latitud,
		&o.Longitud,
		&o.RadioMetros,
	)
	return o, err
}

func (s *service) ListOrganizaciones(ctx context.Context) ([]model.Organizacion, error) {
	return queryRows(
		ctx,
		s.conn.Db,
		`SELECT id, nombre, tipo, codigo_modular_o_ref, sector_ubicacion, responsable_id, latitud, longitud, radio_metros FROM fn_organizacion_listar()`,
		func(rows *sql.Rows) (model.Organizacion, error) { return scanOrganizacion(rows) },
	)
}

func (s *service) GetOrganizacion(ctx context.Context, id int64) (*model.Organizacion, error) {
	o, err := scanOrganizacion(s.conn.Db.QueryRowContext(
		ctx,
		`SELECT id, nombre, tipo, codigo_modular_o_ref, sector_ubicacion, responsable_id, latitud, longitud, radio_metros FROM fn_organizacion_obtener($1)`,
		id,
	))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &o, nil
}

func (s *service) CreateOrganizacion(ctx context.Context, o *model.Organizacion) (int64, error) {
	radio := o.RadioMetros
	if radio <= 0 {
		radio = 80
	}
	var id int64
	err := s.conn.Db.QueryRowContext(
		ctx,
		`SELECT fn_organizacion_crear($1, $2, $3, $4, $5, $6, $7, $8)`,
		o.Nombre,
		o.Tipo,
		o.CodigoModularORef,
		o.SectorUbicacion,
		o.ResponsableId,
		o.Latitud,
		o.Longitud,
		radio,
	).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdateOrganizacion(ctx context.Context, o *model.Organizacion) error {
	radio := o.RadioMetros
	if radio <= 0 {
		radio = 80
	}
	return s.execBool(
		ctx,
		false,
		`SELECT fn_organizacion_actualizar($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		o.Id,
		o.Nombre,
		o.Tipo,
		o.CodigoModularORef,
		o.SectorUbicacion,
		o.ResponsableId,
		o.Latitud,
		o.Longitud,
		radio,
	)
}

func (s *service) DeleteOrganizacion(ctx context.Context, id int64) error {
	return s.execBool(ctx, true, `SELECT fn_organizacion_eliminar($1)`, id)
}
