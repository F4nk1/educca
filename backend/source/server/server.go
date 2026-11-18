package server

import (
	"context"
	"net/http"
	"time"

	"github.com/gorilla/mux"

	"github.com/F4nk1/educca/backend/source/auth"
	"github.com/F4nk1/educca/backend/source/cache"
	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/config"
	"github.com/F4nk1/educca/backend/source/middleware"
	"github.com/F4nk1/educca/backend/source/service"
)

type Server struct {
	Handler http.Handler
	Service service.Service
	Cache   cache.Cache
	QRCache cache.Cache
	Auth    *auth.Auth
	Config  *config.Config
}

func NewServer(service service.Service, cfg *config.Config) *Server {
	s := &Server{
		Service: service,
		Cache:   cache.NewSimpleCache(),
		QRCache: cache.NewSimpleCache(),
		Auth:    auth.NewAuth(cfg.Server.AccessSecret, cfg.Server.RefreshSecret, cfg.Server.QRSecret),
		Config:  cfg,
	}
	s.Handler = s.buildHandler()
	return s
}

func (s *Server) buildHandler() http.Handler {
	router := mux.NewRouter()

	router.HandleFunc("/health", s.health).Methods(http.MethodGet)

	api := router.PathPrefix("/api/v1").Subrouter()

	// Public auth & self-registration routes
	api.HandleFunc("/login", s.login).Methods(http.MethodPost)
	api.HandleFunc("/refresh", s.refreshToken).Methods(http.MethodPost)
	api.HandleFunc("/register", s.register).Methods(http.MethodPost)

	// Protected routes
	protected := api.NewRoute().Subrouter()
	protected.Use(middleware.Auth(s.Auth))
	protected.Use(middleware.Permission(s.Service))
	protected.Use(middleware.Cache(s.Cache))

	protected.HandleFunc("/me", s.me).Methods(http.MethodGet)

	// Personas, RBAC & ARCO
	protected.HandleFunc("/personas", s.listPersonas).Methods(http.MethodGet)
	protected.HandleFunc("/personas", s.createPersona).Methods(http.MethodPost)
	protected.HandleFunc("/personas/{id}", s.getPersona).Methods(http.MethodGet)
	protected.HandleFunc("/personas/{id}", s.updatePersona).Methods(http.MethodPut)
	protected.HandleFunc("/personas/{id}/activo", s.setPersonaActivo).Methods(http.MethodPatch)
	protected.HandleFunc("/personas/{id}/password", s.setPersonaPassword).Methods(http.MethodPatch)
	protected.HandleFunc("/personas/{id}/roles", s.listPersonaRoles).Methods(http.MethodGet)
	protected.HandleFunc("/personas/{id}/roles", s.assignPersonaRol).Methods(http.MethodPost)
	protected.HandleFunc("/personas/{id}/roles/{rol_id}", s.removePersonaRol).Methods(http.MethodDelete)

	protected.HandleFunc("/arco/personas/{id}/exportar", s.exportPersonaArco).Methods(http.MethodGet)
	protected.HandleFunc("/arco/personas/{id}/anonimizar", s.anonimizarPersonaArco).Methods(http.MethodPost)

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

	// EDUCCA / EcoCapacita domain
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

	// Sprint 2: QR Dinámico, Monitoreo, Check-in GPS 80m & Portal del Capacitando
	protected.HandleFunc("/sesiones/{id}/qr", s.generateSesionQR).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/qr", s.getSesionQR).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/qr", s.revokeSesionQR).Methods(http.MethodDelete)
	protected.HandleFunc("/sesiones/{id}/monitoreo", s.getSesionMonitoreo).Methods(http.MethodGet)

	protected.HandleFunc("/sesiones/{id}/inscripciones", s.listInscripcionesBySesion).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/inscripciones", s.createInscripcion).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/inscripciones/mia", s.cancelMyInscripcion).Methods(http.MethodDelete)

	protected.HandleFunc("/mi/inscripciones", s.listMyInscripciones).Methods(http.MethodGet)
	protected.HandleFunc("/mi/asistencias", s.listMyAsistencias).Methods(http.MethodGet)

	protected.HandleFunc("/asistencias/check-in-qr", s.checkInQR).Methods(http.MethodPost)

	protected.HandleFunc("/sesiones/{id}/asistencias", s.listAsistencias).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/asistencias", s.upsertAsistencia).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/asistencias/{persona_id}", s.deleteAsistencia).Methods(http.MethodDelete)

	protected.HandleFunc("/sesiones/{id}/archivos", s.listArchivosSesion).Methods(http.MethodGet)
	protected.HandleFunc("/sesiones/{id}/archivos", s.createArchivoSesion).Methods(http.MethodPost)
	protected.HandleFunc("/sesiones/{id}/archivos/{archivo_id}", s.deleteArchivoSesion).Methods(http.MethodDelete)

	protected.HandleFunc("/reportes/metas", s.getReporteAvanceMetas).Methods(http.MethodGet)

	var allowedOrigins []string
	if s.Config != nil {
		allowedOrigins = s.Config.Server.AllowedOrigins
	}
	return middleware.Correlation(middleware.CorsWithOrigins(allowedOrigins)(router))
}

func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	if s.Service != nil {
		if err := s.Service.Ping(ctx); err != nil {
			common.WriteObjectResponse(w, http.StatusServiceUnavailable, map[string]any{
				"status":   "unhealthy",
				"database": "unreachable",
			})
			return
		}
	}

	common.WriteObjectResponse(w, http.StatusOK, map[string]any{
		"status":   "ok",
		"service":  "educca-api",
		"database": "connected",
	})
}
