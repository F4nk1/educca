package server

import (
	"net/http"
	"strings"

	"github.com/F4nk1/educca/backend/source/common"
	"github.com/F4nk1/educca/backend/source/model"
)

func (s *Server) listRoles(w http.ResponseWriter, r *http.Request) {
	roles, err := s.Service.ListRoles(r.Context())
	if err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, roles)
}

func (s *Server) getRole(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	rol, err := s.Service.GetRole(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, rol)
}

func (s *Server) createRole(w http.ResponseWriter, r *http.Request) {
	var req model.Rol
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.Nombre) == "" || strings.TrimSpace(req.Descripcion) == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	id, err := s.Service.CreateRole(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int16{"id": id})
}

func (s *Server) updateRole(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	var req model.Rol
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.Nombre) == "" || strings.TrimSpace(req.Descripcion) == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	req.Id = id
	if err := s.Service.UpdateRole(r.Context(), &req); err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Role updated")
}

func (s *Server) deleteRole(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	if err := s.Service.DeleteRole(r.Context(), id); err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Role deleted")
}

func (s *Server) listPermisos(w http.ResponseWriter, r *http.Request) {
	permisos, err := s.Service.ListPermisos(r.Context())
	if err != nil {
		writeServiceError(w, r, err, "Permission not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, permisos)
}

func (s *Server) createPermiso(w http.ResponseWriter, r *http.Request) {
	var req model.Permiso
	if !decodeJSON(w, r, &req) {
		return
	}
	if strings.TrimSpace(req.Clave) == "" || strings.TrimSpace(req.Descripcion) == "" {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	id, err := s.Service.CreatePermiso(r.Context(), &req)
	if err != nil {
		writeServiceError(w, r, err, "Permission not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusCreated, map[string]int16{"id": id})
}

func (s *Server) listRolePermisos(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	permisos, err := s.Service.ListRolePermisos(r.Context(), id)
	if err != nil {
		writeServiceError(w, r, err, "Role not found")
		return
	}
	common.WriteObjectResponse(w, http.StatusOK, permisos)
}

func (s *Server) assignRolePermiso(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	var req struct {
		PermisoId int16 `json:"permiso_id"`
	}
	if !decodeJSON(w, r, &req) {
		return
	}
	if req.PermisoId <= 0 {
		common.WriteErrorResponse(w, common.MISSING_FIELDS_ERROR)
		return
	}
	if err := s.Service.AssignRolePermiso(r.Context(), id, req.PermisoId); err != nil {
		writeServiceError(w, r, err, "Role or permission not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusCreated, "Permission assigned to role")
}

func (s *Server) removeRolePermiso(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID[int16](w, r, "id", 16)
	if !ok {
		return
	}
	permisoId, ok := parseID[int16](w, r, "permiso_id", 16)
	if !ok {
		return
	}
	if err := s.Service.RemoveRolePermiso(r.Context(), id, permisoId); err != nil {
		writeServiceError(w, r, err, "Role permission assignment not found")
		return
	}
	common.WriteSuccessResponse(w, http.StatusOK, "Permission removed from role")
}
