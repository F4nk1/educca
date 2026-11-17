package service

import (
	"context"

	"github.com/F4nk1/educca/backend/source/database"
	"github.com/F4nk1/educca/backend/source/model"
)

type Service interface {
	// Auth & RBAC
	Login(ctx context.Context, identificador, password string) (*model.Persona, []string, []string, error)
	GetPersonaRolesPermisos(ctx context.Context, personaId int64) ([]string, []string, error)
	HasPermission(ctx context.Context, personaId int64, permiso string) (bool, error)

	// Persona
	ListPersonas(ctx context.Context) ([]model.Persona, error)
	GetPersona(ctx context.Context, id int64) (*model.Persona, error)
	CreatePersona(ctx context.Context, p *model.Persona, password string) (int64, error)
	UpdatePersona(ctx context.Context, p *model.Persona) error
	SetPersonaActivo(ctx context.Context, id int64, activo bool) error
	SetPersonaPassword(ctx context.Context, id int64, password string) error
	ListPersonaRoles(ctx context.Context, personaId int64) ([]model.Rol, error)
	AssignPersonaRol(ctx context.Context, personaId int64, rolId int16) error
	RemovePersonaRol(ctx context.Context, personaId int64, rolId int16) error

	// Roles & Permisos
	ListRoles(ctx context.Context) ([]model.Rol, error)
	GetRole(ctx context.Context, id int16) (*model.Rol, error)
	CreateRole(ctx context.Context, r *model.Rol) (int16, error)
	UpdateRole(ctx context.Context, r *model.Rol) error
	DeleteRole(ctx context.Context, id int16) error
	ListPermisos(ctx context.Context) ([]model.Permiso, error)
	CreatePermiso(ctx context.Context, p *model.Permiso) (int16, error)
	ListRolePermisos(ctx context.Context, rolId int16) ([]model.Permiso, error)
	AssignRolePermiso(ctx context.Context, rolId, permisoId int16) error
	RemoveRolePermiso(ctx context.Context, rolId, permisoId int16) error

	// Organizacion
	ListOrganizaciones(ctx context.Context) ([]model.Organizacion, error)
	GetOrganizacion(ctx context.Context, id int64) (*model.Organizacion, error)
	CreateOrganizacion(ctx context.Context, o *model.Organizacion) (int64, error)
	UpdateOrganizacion(ctx context.Context, o *model.Organizacion) error
	DeleteOrganizacion(ctx context.Context, id int64) error

	// Meta Anual
	ListMetasAnuales(ctx context.Context, anio *int16) ([]model.MetaAnual, error)
	GetMetaAnual(ctx context.Context, id int64) (*model.MetaAnual, error)
	CreateMetaAnual(ctx context.Context, m *model.MetaAnual) (int64, error)
	UpdateMetaAnual(ctx context.Context, m *model.MetaAnual) error
	DeleteMetaAnual(ctx context.Context, id int64) error

	// Promotor Periodo
	ListPromotoresPeriodo(ctx context.Context, anio *int16) ([]model.PromotorPeriodo, error)
	GetPromotorPeriodo(ctx context.Context, id int64) (*model.PromotorPeriodo, error)
	CreatePromotorPeriodo(ctx context.Context, pp *model.PromotorPeriodo) (int64, error)
	UpdatePromotorPeriodo(ctx context.Context, pp *model.PromotorPeriodo) error
	DeletePromotorPeriodo(ctx context.Context, id int64) error

	// Sesion
	ListSesiones(ctx context.Context, metaAnualId *int64, estado *string) ([]model.Sesion, error)
	GetSesion(ctx context.Context, id int64) (*model.Sesion, error)
	CreateSesion(ctx context.Context, s *model.Sesion) (int64, error)
	UpdateSesion(ctx context.Context, s *model.Sesion) error
	ChangeSesionEstado(ctx context.Context, id int64, estado string) error
	DeleteSesion(ctx context.Context, id int64) error

	// Asistencia
	ListAsistencias(ctx context.Context, sesionId int64) ([]model.Asistencia, error)
	UpsertAsistencia(ctx context.Context, a *model.Asistencia) error
	DeleteAsistencia(ctx context.Context, sesionId, personaId int64) error

	// Archivo Sesion
	ListArchivosSesion(ctx context.Context, sesionId int64) ([]model.ArchivoSesion, error)
	CreateArchivoSesion(ctx context.Context, a *model.ArchivoSesion) (int64, error)
	DeleteArchivoSesion(ctx context.Context, id, sesionId int64) error

	// Reportes
	GetReporteAvanceMetas(ctx context.Context, anio *int16) ([]model.ReporteAvanceMeta, error)
}

type service struct {
	conn *database.Database
}

func NewService(conn *database.Database) Service {
	return &service{conn: conn}
}
