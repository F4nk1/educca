package common

import (
	"net/http"

	"github.com/gorilla/mux"
)

const (
	PermPersonasLeer       = "personas:leer"
	PermPersonasEscribir   = "personas:escribir"
	PermRolesGestionar     = "roles:gestionar"
	PermOrganizacionesLeer = "organizaciones:leer"
	PermOrganizacionesEscr = "organizaciones:escribir"
	PermMetasLeer          = "metas:leer"
	PermMetasEscribir      = "metas:escribir"
	PermPromotoresLeer     = "promotores:leer"
	PermPromotoresEscribir = "promotores:escribir"
	PermSesionesLeer       = "sesiones:leer"
	PermSesionesCrear      = "sesiones:crear"
	PermSesionesValidar    = "sesiones:validar"
	PermAsistenciasReg     = "asistencias:registrar"
	PermArchivosSubir      = "archivos:subir"
	PermReportesExportar   = "reportes:exportar"
)

var RoutePermissions = map[string]map[string]string{
	"/api/v1/personas": {
		http.MethodGet:  PermPersonasLeer,
		http.MethodPost: PermPersonasEscribir,
	},
	"/api/v1/personas/{id}": {
		http.MethodGet: PermPersonasLeer,
		http.MethodPut: PermPersonasEscribir,
	},
	"/api/v1/personas/{id}/activo": {
		http.MethodPatch: PermPersonasEscribir,
	},
	"/api/v1/personas/{id}/roles": {
		http.MethodGet:  PermPersonasLeer,
		http.MethodPost: PermRolesGestionar,
	},
	"/api/v1/personas/{id}/roles/{rol_id}": {
		http.MethodDelete: PermRolesGestionar,
	},
	"/api/v1/roles": {
		http.MethodGet:  PermRolesGestionar,
		http.MethodPost: PermRolesGestionar,
	},
	"/api/v1/roles/{id}": {
		http.MethodGet:    PermRolesGestionar,
		http.MethodPut:    PermRolesGestionar,
		http.MethodDelete: PermRolesGestionar,
	},
	"/api/v1/roles/{id}/permisos": {
		http.MethodGet:  PermRolesGestionar,
		http.MethodPost: PermRolesGestionar,
	},
	"/api/v1/roles/{id}/permisos/{permiso_id}": {
		http.MethodDelete: PermRolesGestionar,
	},
	"/api/v1/permisos": {
		http.MethodGet:  PermRolesGestionar,
		http.MethodPost: PermRolesGestionar,
	},
	"/api/v1/permisos/{id}": {
		http.MethodDelete: PermRolesGestionar,
	},
	"/api/v1/organizaciones": {
		http.MethodGet:  PermOrganizacionesLeer,
		http.MethodPost: PermOrganizacionesEscr,
	},
	"/api/v1/organizaciones/{id}": {
		http.MethodGet:    PermOrganizacionesLeer,
		http.MethodPut:    PermOrganizacionesEscr,
		http.MethodDelete: PermOrganizacionesEscr,
	},
	"/api/v1/metas-anuales": {
		http.MethodGet:  PermMetasLeer,
		http.MethodPost: PermMetasEscribir,
	},
	"/api/v1/metas-anuales/{id}": {
		http.MethodGet:    PermMetasLeer,
		http.MethodPut:    PermMetasEscribir,
		http.MethodDelete: PermMetasEscribir,
	},
	"/api/v1/promotores": {
		http.MethodGet:  PermPromotoresLeer,
		http.MethodPost: PermPromotoresEscribir,
	},
	"/api/v1/promotores/{id}": {
		http.MethodGet:    PermPromotoresLeer,
		http.MethodPut:    PermPromotoresEscribir,
		http.MethodDelete: PermPromotoresEscribir,
	},
	"/api/v1/sesiones": {
		http.MethodGet:  PermSesionesLeer,
		http.MethodPost: PermSesionesCrear,
	},
	"/api/v1/sesiones/{id}": {
		http.MethodGet:    PermSesionesLeer,
		http.MethodPut:    PermSesionesCrear,
		http.MethodDelete: PermSesionesCrear,
	},
	"/api/v1/sesiones/{id}/asistencias": {
		http.MethodGet:  PermSesionesLeer,
		http.MethodPost: PermAsistenciasReg,
	},
	"/api/v1/sesiones/{id}/asistencias/{persona_id}": {
		http.MethodDelete: PermAsistenciasReg,
	},
	"/api/v1/sesiones/{id}/archivos": {
		http.MethodGet:  PermSesionesLeer,
		http.MethodPost: PermArchivosSubir,
	},
	"/api/v1/sesiones/{id}/archivos/{archivo_id}": {
		http.MethodDelete: PermArchivosSubir,
	},
	"/api/v1/reportes/metas": {
		http.MethodGet: PermReportesExportar,
	},
}

// GetRequiredPermission returns the permission key for the matched route, or empty string when none is required.
func GetRequiredPermission(r *http.Request) string {
	route := mux.CurrentRoute(r)
	if route == nil {
		return ""
	}
	template, err := route.GetPathTemplate()
	if err != nil {
		return ""
	}
	if methods, exists := RoutePermissions[template]; exists {
		return methods[r.Method]
	}
	return ""
}
