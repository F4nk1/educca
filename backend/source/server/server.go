package server

import (
	"net/http"

	"github.com/gorilla/mux"

	"github.com/F4nk1/educca/backend/source/auth"
	"github.com/F4nk1/educca/backend/source/cache"
	"github.com/F4nk1/educca/backend/source/config"
	"github.com/F4nk1/educca/backend/source/middleware"
	"github.com/F4nk1/educca/backend/source/service"
)

type Server struct {
	Handler http.Handler
	Service service.Service
	Cache   cache.Cache
	Auth    *auth.Auth
}

func NewServer(service service.Service, cfg *config.Config) *Server {
	s := &Server{
		Service: service,
		Cache:   cache.NewSimpleCache(),
		Auth:    auth.NewAuth(cfg.Server.AccessSecret, cfg.Server.RefreshSecret),
	}
	s.Handler = s.buildHandler()
	return s
}

func (s *Server) buildHandler() http.Handler {
	router := mux.NewRouter()

	api := router.PathPrefix("/api/v1").Subrouter()

	// Public auth routes
	api.HandleFunc("/login", s.login).Methods(http.MethodPost)
	api.HandleFunc("/refresh", s.refreshToken).Methods(http.MethodPost)

	// Protected routes
	protected := api.NewRoute().Subrouter()
	protected.Use(middleware.Auth(s.Auth))
	protected.Use(middleware.Permission(s.Service))
	protected.Use(middleware.Cache(s.Cache))

	protected.HandleFunc("/me", s.me).Methods(http.MethodGet)

	// Personas & RBAC
	protected.HandleFunc("/personas", s.listPersonas).Methods(http.MethodGet)
	protected.HandleFunc("/personas", s.createPersona).Methods(http.MethodPost)
	protected.HandleFunc("/personas/{id}", s.getPersona).Methods(http.MethodGet)
	protected.HandleFunc("/personas/{id}", s.updatePersona).Methods(http.MethodPut)
	protected.HandleFunc("/personas/{id}/activo", s.setPersonaActivo).Methods(http.MethodPatch)
	protected.HandleFunc("/personas/{id}/password", s.setPersonaPassword).Methods(http.MethodPatch)
	protected.HandleFunc("/personas/{id}/roles", s.listPersonaRoles).Methods(http.MethodGet)
	protected.HandleFunc("/personas/{id}/roles", s.assignPersonaRol).Methods(http.MethodPost)
	protected.HandleFunc("/personas/{id}/roles/{rol_id}", s.removePersonaRol).Methods(http.MethodDelete)

	protected.HandleFunc("/roles", s.listRoles).Methods(http.MethodGet)
	protected.HandleFunc("/roles", s.createRole).Methods(http.MethodPost)
	protected.HandleFunc("/roles/{id}", s.getRole).Methods(http.MethodGet)
	protected.HandleFunc("/roles/{id}", s.updateRole).Methods(http.MethodPut)
	protected.HandleFunc("/roles/{id}", s.deleteRole).Methods(http.MethodDelete)
	protected.HandleFunc("/roles/{id}/permisos", s.listRolePermisos).Methods(http.MethodGet)
	protected.HandleFunc("/roles/{id}/permisos", s.assignRolePermiso).Methods(http.MethodPost)
	protected.HandleFunc("/roles/{id}/permisos/{permiso_id}", s.removeRolePermiso).Methods(http.MethodDelete)

	protected.HandleFunc("/permisos", s.listPermisos).Methods(http.MethodGet)
	protected.HandleFunc("/permisos", s.createPermiso).Methods(http.MethodPost)
	protected.HandleFunc("/permisos/{id}", s.deletePermiso).Methods(http.MethodDelete)

	// EDUCCA domain
	protected.HandleFunc("/organizaciones", s.listOrganizaciones).Methods(http.MethodGet)
	protected.HandleFunc("/organizaciones", s.createOrganizacion).Methods(http.MethodPost)
	protected.HandleFunc("/organizaciones/{id}", s.getOrganizacion).Methods(http.MethodGet)
	protected.HandleFunc("/organizaciones/{id}", s.updateOrganizacion).Methods(http.MethodPut)
	protected.HandleFunc("/organizaciones/{id}", s.deleteOrganizacion).Methods(http.MethodDelete)

	protected.HandleFunc("/metas-anuales", s.listMetasAnuales).Methods(http.MethodGet)
	protected.HandleFunc("/metas-anuales", s.createMetaAnual).Methods(http.MethodPost)
	protected.HandleFunc("/metas-anuales/{id}", s.getMetaAnual).Methods(http.MethodGet)
	protected.HandleFunc("/metas-anuales/{id}", s.updateMetaAnual).Methods(http.MethodPut)
	protected.HandleFunc("/metas-anuales/{id}", s.deleteMetaAnual).Methods(http.MethodDelete)

	protected.HandleFunc("/promotores", s.listPromotoresPeriodo).Methods(http.MethodGet)
	protected.HandleFunc("/promotores", s.createPromotorPeriodo).Methods(http.MethodPost)
	protected.HandleFunc("/promotores/{id}", s.getPromotorPeriodo).Methods(http.MethodGet)
	protected.HandleFunc("/promotores/{id}", s.updatePromotorPeriodo).Methods(http.MethodPut)
	protected.HandleFunc("/promotores/{id}", s.deletePromotorPeriodo).Methods(http.MethodDelete)

	protected.HandleFunc("/sesiones", s.listSesiones).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones", s.createSesion).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}", s.getSesion).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}", s.updateSesion).Methods(http.MethodPut)
	protected.HandleFunc("/sesiones/{id}/estado", s.changeSesionEstado).Methods(http.MethodPatch)
	protected.HandleFunc("/sesiones/{id}", s.deleteSesion).Methods(http.MethodDelete)

	protected.HandleFunc("/sesiones/{id}/asistencias", s.listAsistencias).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/asistencias", s.upsertAsistencia).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/asistencias/{persona_id}", s.deleteAsistencia).Methods(http.MethodDelete)

	protected.HandleFunc("/sesiones/{id}/archivos", s.listArchivosSesion).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/archivos", s.createArchivoSesion).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/archivos/{archivo_id}", s.deleteArchivoSesion).Methods(http.MethodDelete)

	protected.HandleFunc("/reportes/metas", s.getReporteAvanceMetas).Methods(http.MethodGet)

	return middleware.Correlation(middleware.Cors(router))
}
