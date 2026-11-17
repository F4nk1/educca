package service

import (
	"context"
	"database/sql"

	"github.com/F4nk1/educca/backend/source/model"
)

func scanRol(s interface{ Scan(...any) error }) (model.Rol, error) {
	var r model.Rol
	err := s.Scan(&r.Id, &r.Nombre, &r.Descripcion)
	return r, err
}

func scanPermiso(s interface{ Scan(...any) error }) (model.Permiso, error) {
	var p model.Permiso
	err := s.Scan(&p.Id, &p.Clave, &p.Descripcion)
	return p, err
}

func (s *service) ListRoles(ctx context.Context) ([]model.Rol, error) {
	return queryRows(ctx, s.conn.Db, `SELECT id, nombre, descripcion FROM fn_rol_listar()`,
		func(rows *sql.Rows) (model.Rol, error) { return scanRol(rows) })
}

func (s *service) GetRole(ctx context.Context, id int16) (*model.Rol, error) {
	r, err := scanRol(s.conn.Db.QueryRowContext(ctx, `SELECT id, nombre, descripcion FROM fn_rol_obtener($1)`, id))
	if err != nil {
		return nil, classifyError(err, false)
	}
	return &r, nil
}

func (s *service) CreateRole(ctx context.Context, r *model.Rol) (int16, error) {
	var id int16
	err := s.conn.Db.QueryRowContext(ctx, `SELECT fn_rol_crear($1, $2)`, r.Nombre, r.Descripcion).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) UpdateRole(ctx context.Context, r *model.Rol) error {
	return s.execBool(ctx, false, `SELECT fn_rol_actualizar($1, $2, $3)`, r.Id, r.Nombre, r.Descripcion)
}

func (s *service) DeleteRole(ctx context.Context, id int16) error {
	return s.execBool(ctx, true, `SELECT fn_rol_eliminar($1)`, id)
}

func (s *service) ListPermisos(ctx context.Context) ([]model.Permiso, error) {
	return queryRows(ctx, s.conn.Db, `SELECT id, clave, descripcion FROM fn_permiso_listar()`,
		func(rows *sql.Rows) (model.Permiso, error) { return scanPermiso(rows) })
}

func (s *service) CreatePermiso(ctx context.Context, p *model.Permiso) (int16, error) {
	var id int16
	err := s.conn.Db.QueryRowContext(ctx, `SELECT fn_permiso_crear($1, $2)`, p.Clave, p.Descripcion).Scan(&id)
	if err != nil {
		return 0, classifyError(err, false)
	}
	return id, nil
}

func (s *service) ListRolePermisos(ctx context.Context, rolId int16) ([]model.Permiso, error) {
	return queryRows(ctx, s.conn.Db, `SELECT id, clave, descripcion FROM fn_rol_listar_permisos($1)`,
		func(rows *sql.Rows) (model.Permiso, error) { return scanPermiso(rows) }, rolId)
}

func (s *service) AssignRolePermiso(ctx context.Context, rolId, permisoId int16) error {
	_, err := s.conn.Db.ExecContext(ctx, `SELECT fn_rol_asignar_permiso($1, $2)`, rolId, permisoId)
	return classifyError(err, false)
}

func (s *service) RemoveRolePermiso(ctx context.Context, rolId, permisoId int16) error {
	return s.execBool(ctx, true, `SELECT fn_rol_quitar_permiso($1, $2)`, rolId, permisoId)
}
